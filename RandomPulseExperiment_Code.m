function results = RandomPulseExperiment_Code(cfg)
% RandomPulseExperiment_Code
% Code-only (no AppDesigner dependency) runner for random-pulse experiments.
%
% Goal of this first version:
%   1) Keep your existing random pulse generator (CreateRandomPulses) intact.
%   2) Use your instrument classes directly (ClassAWG / ClassPicoharp /
%      ClassLightFieldWrapper / ClassKeysightSupply).
%   3) Stay gentle and readable so we can evolve this together.
%
% Usage:
%   cfg = RandomPulseExperiment_DefaultConfig();
%   cfg.DryRun = true;     % safest first run
%   results = RandomPulseExperiment_Code(cfg);

    if nargin < 1 || isempty(cfg)
        cfg = RandomPulseExperiment_DefaultConfig();
    end

    validateConfig(cfg);

    results = struct();
    results.Timestamp = datetime('now');
    results.Config = cfg;
    results.Sequence = struct();
    results.Acquisition = struct();

    % ---------------------------------------------------------------------
    % 1) AWG setup + waveform build (this is the core "code part")
    % ---------------------------------------------------------------------
    awg = ClassAWG.getInstance();

    if ~cfg.DryRun
        awg.connect(2);  % Rotation + Initialization signals
    end

    awg.SetChannels(cfg.Channels, 1:4, cfg.UserDelaysNs);

    % Build the random rotation waveform using your existing implementation.
    rotWaveform = CreateRandomPulses(awg, ...
        cfg.Random.M, ...
        cfg.Random.ka, ...
        cfg.Random.InitDurationNs, ...
        cfg.Random.PiDurationNs, ...
        cfg.Random.TauNs, ...
        cfg.Random.TauInitialNs, ...
        cfg.Random.FrequencyGHz, ...
        cfg.Random.Frame);

    % Build a simple initialization level for the same total duration.
    totalDurationNs = estimateRandomSequenceDuration(cfg.Random);
    [initWaveform, ~] = awg.CreateWaveform( ...
        totalDurationNs, {'dc'}, {struct('Offset', cfg.InitAmplitude)}, 1);

    % Optional pre-block for bath polarization (as in Echo_Experiment logic).
    if cfg.BathPolarization.Enable
        [bathInit, bathRot] = createBathPolarizationWaveforms(awg, cfg.BathPolarization);
        initWaveform = [bathInit, initWaveform];
        rotWaveform = [bathRot, rotWaveform];
    end

    % Simple trigger: high for the first few samples.
    triggerWaveform = zeros(1, numel(rotWaveform));
    triggerLen = min(32, numel(triggerWaveform));
    triggerWaveform(1:triggerLen) = cfg.TriggerAmplitude;

    % Make all channels equal-length and package a segment.
    [initWaveform, rotWaveform, triggerWaveform] = alignLengths( ...
        initWaveform, rotWaveform, triggerWaveform);

    segment = cell(1, 4);
    segment{1} = initWaveform;
    segment{2} = rotWaveform;
    segment{3} = triggerWaveform;
    segment{4} = zeros(1, numel(initWaveform));

    results.Sequence.TotalSamples = numel(initWaveform);
    results.Sequence.TotalDurationNs = numel(initWaveform) * awg.AWGStep;
    results.Sequence.AWGStepNs = awg.AWGStep;

    if ~cfg.DryRun
        awg.RunSegment(segment);
        results.Sequence.Uploaded = true;
    else
        results.Sequence.Uploaded = false;
    end

    % ---------------------------------------------------------------------
    % 2) Optional instrument hooks (first-pass integration placeholders)
    % ---------------------------------------------------------------------
    if cfg.Supply.Enable
        configureSupply(cfg, results);
    end

    switch lower(string(cfg.Acquisition.Mode))
        case "none"
            results.Acquisition.Mode = 'none';
            results.Acquisition.Note = 'No detector readout requested.';

        case "picoharp"
            results.Acquisition = runPicoHarp(cfg, cfg.DryRun);

        case "spectrometer"
            results.Acquisition = runSpectrometer(cfg, cfg.DryRun);

        otherwise
            error('Unsupported acquisition mode: %s', cfg.Acquisition.Mode);
    end

    % Keep quick visibility in command window when developing.
    fprintf('Random pulse code run finished. DryRun=%d, Samples=%d, Duration=%.3f ns\n', ...
        cfg.DryRun, results.Sequence.TotalSamples, results.Sequence.TotalDurationNs);
end

function totalNs = estimateRandomSequenceDuration(r)
% Rough timing model matching CreateRandomPulses section order.
    totalNs = r.InitDurationNs + r.TauInitialNs + ...
        (r.PiDurationNs / 2) + ...       % first pi/2
        (r.TauNs / 2) + ...              % first tau/2
        (r.M * r.PiDurationNs) + ...     % all pi slots
        ((r.M - 1) * r.TauNs) + ...      % taus between pi slots
        (r.TauNs / 2) + ...              % final tau/2
        (r.PiDurationNs / 2) + ...       % final pi/2
        (r.TauNs / 2);                   % final wait
end

function [a, b, c] = alignLengths(a, b, c)
% Pads with zeros so all channels share exactly one segment length.
    L = max([numel(a), numel(b), numel(c)]);
    a(end+1:L) = 0;
    b(end+1:L) = 0;
    c(end+1:L) = 0;
end


function [initWaveform, rotWaveform] = createBathPolarizationWaveforms(awg, bath)
% Creates a short prep block before the random sequence.
% - Initialization channel: constant level
% - Rotation channel: continuous sine

    [initWaveform, ~] = awg.CreateWaveform( ...
        bath.DurationNs, {'dc'}, {struct('Offset', bath.InitAmplitude)}, 1);

    rotParams = struct('Amplitude', bath.RotAmplitude, ...
                       'Frequency', bath.RotFrequencyGHz, ...
                       'Phase', 0, ...
                       'Frame', bath.Frame, ...
                       'Offset', 0);
    [rotWaveform, ~] = awg.CreateWaveform(bath.DurationNs, {'sine'}, {rotParams}, 2);
end

function acq = runPicoHarp(cfg, dryRun)
    acq = struct('Mode', 'picoharp');

    if dryRun
        acq.Note = 'DryRun=true, skipped PicoHarp hardware calls.';
        return;
    end

    ph = ClassPicoharp.getInstance();
    ph.connect();
    ph.SetResolution(cfg.PicoHarp.ResolutionPs);
    ph.SetTimeStop(cfg.PicoHarp.AcquisitionTimeS);

    ph.StartAcquisition();
    pause(cfg.PicoHarp.AcquisitionTimeS + 0.1);  % keep simple for now
    [t, h] = ph.GetHistogram();
    ph.StopAcquisition();

    acq.TimeNs = t;
    acq.Counts = h;
end

function acq = runSpectrometer(cfg, dryRun)
    acq = struct('Mode', 'spectrometer');

    if dryRun
        acq.Note = 'DryRun=true, skipped LightField hardware calls.';
        return;
    end

    lf = ClassLightFieldWrapper(cfg.Spectrometer.Visible, cfg.Spectrometer.ExperimentName);
    lf.setExposureMs(cfg.Spectrometer.ExposureMs);
    lf.setFrames(cfg.Spectrometer.Frames);
    lf.setCenterWavelengthNm(cfg.Spectrometer.CenterWavelengthNm);
    lf.setExitPort(cfg.Spectrometer.ExitPort);

    [data, wl] = lf.acquire();

    acq.Data = data;
    acq.WavelengthNm = wl;

    lf.close();
end

function configureSupply(cfg, results)
% Minimal hook to prepare a DC bias source if needed by the sequence.
% The result struct is intentionally not modified here yet; this helper is
% only side-effect hardware config in v1.
    %#ok<INUSD>

    supply = ClassKeysightSupply.getInstance();
    supply.connect(cfg.Supply.Name);

    if strcmpi(cfg.Supply.Name, 'TriplePowerSupply')
        supply.setVoltage(cfg.Supply.Voltage, cfg.Supply.Channel);
    else
        supply.setVoltage(cfg.Supply.Voltage);
    end
end

function validateConfig(cfg)
% Lightweight config checks so mistakes fail early and clearly.
    requiredTopFields = {'DryRun', 'Channels', 'UserDelaysNs', 'Random', 'BathPolarization', 'Acquisition'};
    for k = 1:numel(requiredTopFields)
        assert(isfield(cfg, requiredTopFields{k}), ...
            'Missing cfg.%s', requiredTopFields{k});
    end

    assert(numel(cfg.Channels) == 4, 'cfg.Channels must contain exactly 4 entries.');
    assert(numel(cfg.UserDelaysNs) == 4, 'cfg.UserDelaysNs must contain exactly 4 values.');
    assert(cfg.Random.M >= 1, 'cfg.Random.M must be >= 1');
    assert(cfg.BathPolarization.DurationNs >= 0, 'cfg.BathPolarization.DurationNs must be >= 0');
end
