function results = RandomPulseExperiment_Code(cfg)
% RandomPulseExperiment_Code
% Code-only (no AppDesigner dependency) runner for random-pulse experiments.
%
% This version explicitly supports:
%   - N2: repetitions of one full pulse sequence.
%   - N1: random realizations per basis.
%   - Interrogation timing from total T and M:
%       tau = T/M, tau_initial = T/(2M), same half-interval at the end.
%
% Usage:
%   cfg = RandomPulseExperiment_DefaultConfig();
%   cfg.DryRun = true;
%   results = RandomPulseExperiment_Code(cfg);

    if nargin < 1 || isempty(cfg)
        cfg = RandomPulseExperiment_DefaultConfig();
    end

    validateConfig(cfg);

    timing = resolveRandomTiming(cfg.Random);

    results = struct();
    results.Timestamp = datetime('now');
    results.Config = cfg;
    results.Timing = timing;
    results.Sequence = struct();
    results.Sequence.Library = struct([]);
    results.Acquisition = struct();

    awg = ClassAWG.getInstance();

    if ~cfg.DryRun
        awg.connect(2);
    end

    awg.SetChannels(cfg.Channels, 1:4, cfg.UserDelaysNs);

    % Build a segment library with explicit Basis x Realization indexing.
    entryIdx = 0;
    for b = 1:numel(cfg.BasisList)
        basisName = cfg.BasisList{b};

        for r = 1:cfg.N1
            entryIdx = entryIdx + 1;

            [segment, meta] = buildSegmentForOneRealization(awg, cfg, timing, basisName);

            results.Sequence.Library(entryIdx).Basis = basisName;
            results.Sequence.Library(entryIdx).RealizationIndex = r;
            results.Sequence.Library(entryIdx).N2Repetitions = cfg.N2;
            results.Sequence.Library(entryIdx).TotalSamples = numel(segment{1});
            results.Sequence.Library(entryIdx).TotalDurationNs = numel(segment{1}) * awg.AWGStep;
            results.Sequence.Library(entryIdx).Meta = meta;

            if ~cfg.DryRun
                awg.RunSegment(segment);
            end
        end
    end

    results.Sequence.BasisCount = numel(cfg.BasisList);
    results.Sequence.RealizationsPerBasis = cfg.N1;
    results.Sequence.TotalSegmentsBuilt = numel(results.Sequence.Library);
    results.Sequence.AWGStepNs = awg.AWGStep;
    results.Sequence.Uploaded = ~cfg.DryRun;

    if cfg.Supply.Enable
        configureSupply(cfg);
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

    fprintf(['Random pulse code run finished. DryRun=%d, Basis=%d, ' ...
             'N1=%d, N2=%d, Segments=%d\n'], ...
        cfg.DryRun, numel(cfg.BasisList), cfg.N1, cfg.N2, results.Sequence.TotalSegmentsBuilt);
end

function [segment, meta] = buildSegmentForOneRealization(awg, cfg, timing, basisName)
% Build one random realization for one basis and repeat it N2 times.

    % Keep using the existing random-pulse implementation.
    singleRot = CreateRandomPulses(awg, ...
        cfg.Random.M, ...
        cfg.Random.ka, ...
        cfg.Random.InitDurationNs, ...
        cfg.Random.PiDurationNs, ...
        timing.TauNs, ...
        timing.TauInitialNs, ...
        cfg.Random.FrequencyGHz, ...
        cfg.Random.Frame);

    totalSingleDurationNs = estimateSingleSequenceDuration(cfg.Random, timing);
    [singleInit, ~] = awg.CreateWaveform( ...
        totalSingleDurationNs, {'dc'}, {struct('Offset', cfg.InitAmplitude)}, 1);

    % Trigger pulse at start of each repeated sequence block.
    singleTrigger = zeros(1, numel(singleRot));
    triggerLen = min(32, numel(singleTrigger));
    singleTrigger(1:triggerLen) = cfg.TriggerAmplitude;

    [singleInit, singleRot, singleTrigger] = alignLengths(singleInit, singleRot, singleTrigger);

    % N2 repetitions of one full sequence (init -> next init boundary).
    initWaveform = repmat(singleInit, 1, cfg.N2);
    rotWaveform = repmat(singleRot, 1, cfg.N2);
    triggerWaveform = repmat(singleTrigger, 1, cfg.N2);

    % Optional bath polarization pre-block (once per realization).
    if cfg.BathPolarization.Enable
        [bathInit, bathRot] = createBathPolarizationWaveforms(awg, cfg.BathPolarization);
        initWaveform = [bathInit, initWaveform];
        rotWaveform = [bathRot, rotWaveform];
        triggerWaveform = [zeros(1, numel(bathRot)), triggerWaveform];
    end

    [initWaveform, rotWaveform, triggerWaveform] = alignLengths(initWaveform, rotWaveform, triggerWaveform);

    segment = cell(1, 4);
    segment{1} = initWaveform;
    segment{2} = rotWaveform;
    segment{3} = triggerWaveform;
    segment{4} = zeros(1, numel(initWaveform));

    meta = struct();
    meta.Basis = basisName;
    meta.SingleSequenceDurationNs = totalSingleDurationNs;
    meta.InterrogationTimeNs = timing.TotalInterrogationTimeNs;
    meta.TauNs = timing.TauNs;
    meta.TauInitialNs = timing.TauInitialNs;
end

function timing = resolveRandomTiming(randomCfg)
% Translate user-requested (T, M) into tau and tau_initial.
% By definition here:
%   tau = T/M
%   tau_initial = T/(2M)
% and the same half interval is used before the last pi/2.

    timing = struct();
    timing.TotalInterrogationTimeNs = randomCfg.TotalInterrogationTimeNs;
    timing.TauNs = randomCfg.TotalInterrogationTimeNs / randomCfg.M;
    timing.TauInitialNs = randomCfg.TotalInterrogationTimeNs / (2 * randomCfg.M);
end

function totalNs = estimateSingleSequenceDuration(randomCfg, timing)
% Sequence duration from init start to the end of final wait.

    totalNs = randomCfg.InitDurationNs + timing.TauInitialNs + ...
        (randomCfg.PiDurationNs / 2) + ...           % first pi/2
        timing.TauInitialNs + ...                    % first free interval (T/2M)
        (randomCfg.M * randomCfg.PiDurationNs) + ... % M pi slots
        ((randomCfg.M - 1) * timing.TauNs) + ...     % inner free intervals (T/M)
        timing.TauInitialNs + ...                    % last free interval (T/2M)
        (randomCfg.PiDurationNs / 2) + ...           % final pi/2
        timing.TauInitialNs;                         % final wait (kept symmetric)
end

function [a, b, c] = alignLengths(a, b, c)
    L = max([numel(a), numel(b), numel(c)]);
    a(end+1:L) = 0;
    b(end+1:L) = 0;
    c(end+1:L) = 0;
end

function [initWaveform, rotWaveform] = createBathPolarizationWaveforms(awg, bath)
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
    pause(cfg.PicoHarp.AcquisitionTimeS + 0.1);
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

function configureSupply(cfg)
    supply = ClassKeysightSupply.getInstance();
    supply.connect(cfg.Supply.Name);

    if strcmpi(cfg.Supply.Name, 'TriplePowerSupply')
        supply.setVoltage(cfg.Supply.Voltage, cfg.Supply.Channel);
    else
        supply.setVoltage(cfg.Supply.Voltage);
    end
end

function validateConfig(cfg)
    requiredTopFields = {'DryRun', 'Channels', 'UserDelaysNs', 'N1', 'N2', ...
        'BasisList', 'Random', 'BathPolarization', 'Acquisition'};
    for k = 1:numel(requiredTopFields)
        assert(isfield(cfg, requiredTopFields{k}), 'Missing cfg.%s', requiredTopFields{k});
    end

    assert(numel(cfg.Channels) == 4, 'cfg.Channels must contain exactly 4 entries.');
    assert(numel(cfg.UserDelaysNs) == 4, 'cfg.UserDelaysNs must contain exactly 4 values.');
    assert(cfg.N1 >= 1 && mod(cfg.N1,1)==0, 'cfg.N1 must be a positive integer.');
    assert(cfg.N2 >= 1 && mod(cfg.N2,1)==0, 'cfg.N2 must be a positive integer.');
    assert(~isempty(cfg.BasisList), 'cfg.BasisList cannot be empty.');

    assert(cfg.Random.M >= 1, 'cfg.Random.M must be >= 1');
    assert(cfg.Random.TotalInterrogationTimeNs > 0, 'cfg.Random.TotalInterrogationTimeNs must be > 0');
    assert(cfg.BathPolarization.DurationNs >= 0, 'cfg.BathPolarization.DurationNs must be >= 0');
end
