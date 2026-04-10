% MeasureESR.m
% ESR (Electron Spin Resonance) experiment.
% Set the parameters in this block, then press Run.
%
% LASER power and frequency are set manually — this code plays no role in
% laser control.  The initialization and rotation modulators are biased via
% the TriplePowerSupply on the channels and voltages specified below.
%
% Sequence per MW-frequency point (N points total per AWG period):
%   Ch1 (Init):     [off] [ON ] [off          ] [off  ] [ON     ]
%   Ch2 (Rotation): [off] [off] [sine @ f_MW  ] [off  ] [off    ]
%   Ch3 (Trigger):  active for first half of full sequence
%                   <dark> <init> <rotation> <delay> <readout>
%
% Signal(i) = (readout_counts(i) - dark_counts(i)) / (init_counts(i) - dark_counts(i))
% Plotted vs. mwFrequencies_GHz after reordering from the sweep order.

% =========================================================================
% USER SETTINGS — edit here, then press Run
% =========================================================================

initModulatorChannel   = 2;    % TriplePowerSupply channel for initialization bias (1, 2, or 3)
initModulatorVoltage_V = 2.97; % Initialization modulator bias voltage (V)
rotModulatorChannel    = 3;    % TriplePowerSupply channel for rotation bias (1, 2, or 3)
rotModulatorVoltage_V  = 2.97; % Rotation modulator bias voltage (V)

mwFrequencies_GHz = 2.85:0.002:2.90;  % MW frequency sweep array (GHz)

darkCountDuration_ns     = 5;    % Dark-count window duration (ns)
initPulseDuration_ns     = 10;   % Initialization pulse duration (ns)
rotationPulseDuration_ns = 100;  % MW rotation pulse duration (ns)
delayAfterRotation_ns    = 5;    % Delay from rotation-pulse end to readout pulse (ns)
rR  = 5;    % Readout pulse duration (ns)

initPulseHeight   = 1.0;   % AWG user level for init/readout optical pulses (> 0.5)
rotationAmplitude = 0.4;   % Normalized amplitude for the rotation sine wave (0–1)
rotationFrame     = 'lab'; % Sine-wave frame: 'lab' or 'rotating'

isRandomized = true;       % true = randomise MW-frequency order each run

% Trigger voltage levels (detector-dependent)
picoharpTriggerLowVoltage_V  = -0.8;
picoharpTriggerHighVoltage_V =  0.2;
timetaggerTriggerLowVoltage_V  = 0.0;
timetaggerTriggerHighVoltage_V = 1.0;

acquisitionDevice = 'TimeTagger'; % 'Picoharp' or 'TimeTagger'
acquisitionTime_s    = 30;
binResolution_ps     = 512;
plotWaveforms        = true;

% TimeTagger physical channel numbers (set to match your cabling)
timetaggerTriggerCh = 1;  % TimeTagger channel wired to AWG Ch3
timetaggerPhotonCh  = 2;  % TimeTagger channel wired to the photon detector

awgUserDelays_ns = [0, 0, 0, 0];  % [Ch1 Ch2 Ch3 Ch4] cable-delay corrections (ns)

shouldSaveResults = false;
outputFolder  = '';
baseFileName  = 'ESR_Experiment';

% =========================================================================
% CONFIG ASSEMBLY — do not edit below unless you know what you are doing
% =========================================================================

cfg.waveform.mwFrequencies_GHz        = mwFrequencies_GHz;
cfg.waveform.darkCountDuration_ns     = darkCountDuration_ns;
cfg.waveform.initPulseDuration_ns     = initPulseDuration_ns;
cfg.waveform.rotationPulseDuration_ns = rotationPulseDuration_ns;
cfg.waveform.delayAfterRotation_ns    = delayAfterRotation_ns;
cfg.waveform.readoutPulseDuration_ns  = readoutPulseDuration_ns;
cfg.waveform.isRandomized             = isRandomized;

cfg.awg.channelInit    = 1;
cfg.awg.channelRot     = 2;
cfg.awg.channelTrigger = 3;
cfg.awg.userDelays_ns  = awgUserDelays_ns;
cfg.awg.initOnUserLevel   = initPulseHeight;
cfg.awg.initOffUserLevel  = 0.5;  % Internal AWG level that gives 0 V on Ch1.
cfg.awg.rotationAmplitude = rotationAmplitude;
cfg.awg.rotationFrame     = rotationFrame;
cfg.awg.settleTime_s      = 0.5;

cfg.acquisition.device        = acquisitionDevice;
cfg.acquisition.time_s        = acquisitionTime_s;
cfg.acquisition.resolution_ps = binResolution_ps;
cfg.acquisition.pollPeriod_s  = 0.25;

cfg.picoharp.histogramOffset_ps     = 0;
cfg.picoharp.syncOffset_ps          = 0;
cfg.picoharp.syncDiscriminator_mV   = 50;
cfg.picoharp.syncZeroCross_mV       = 10;
cfg.picoharp.signalDiscriminator_mV = 50;
cfg.picoharp.signalZeroCross_mV     = 10;
cfg.picoharp.countStop              = 65535;

cfg.timetagger.triggerChannel = timetaggerTriggerCh;
cfg.timetagger.photonChannel  = timetaggerPhotonCh;
cfg.timetagger.triggerLevel_V = 0.10;
cfg.timetagger.photonLevel_V  = 0.05;

cfg.supply.initVoltage_V  = initModulatorVoltage_V;
cfg.supply.initChannel    = initModulatorChannel;
cfg.supply.rotVoltage_V   = rotModulatorVoltage_V;
cfg.supply.rotChannel     = rotModulatorChannel;
cfg.supply.currentLimit_A = 0.01;
cfg.supply.settleTime_s   = 0.25;

cfg.analysis.syncPeriodTolerance_ns = 2.0;

cfg.output.saveResults  = shouldSaveResults;
cfg.output.outputFolder = outputFolder;
cfg.output.baseFileName = baseFileName;

cfg.debug.plotWaveforms = plotWaveforms;

cfg.cleanup.turnOutputsOff        = true;
cfg.cleanup.disconnectInstruments = true;

if strcmpi(cfg.acquisition.device, 'Picoharp')
    cfg.awg.triggerLowVoltage_V  = picoharpTriggerLowVoltage_V;
    cfg.awg.triggerHighVoltage_V = picoharpTriggerHighVoltage_V;
else
    cfg.awg.triggerLowVoltage_V  = timetaggerTriggerLowVoltage_V;
    cfg.awg.triggerHighVoltage_V = timetaggerTriggerHighVoltage_V;
end

results = runMeasureESRInternal(cfg);

% =========================================================================
% INTERNAL FUNCTIONS
% =========================================================================

function results = runMeasureESRInternal(cfg)
    cfg = validateConfig(cfg);
    addpath(fileparts(mfilename('fullpath')));

    awg      = [];
    detector = [];
    supply   = [];
    cleanupObj = onCleanup(@() cleanupInstruments(awg, detector, supply, cfg)); %#ok<NASGU>

    figures  = createFigures(cfg);

    awg      = ClassAWG.getInstance();
    detector = createDetectorHandle(cfg);
    supply   = ClassKeysightSupply.getInstance();

    connectAndConfigureInstruments(awg, detector, supply, cfg);
    timing = buildAndRunSequence(awg, cfg, figures);
    prepareDetectorForSequence(detector, timing, cfg);
    reportDetectorRates(detector, cfg);

    pause(cfg.awg.settleTime_s);
    syncRate_Hz = 0;
    syncPollTimeout_s  = 10.0;
    syncPollInterval_s = 0.5;
    syncWaited_s       = 0;
    while syncRate_Hz <= 0 && syncWaited_s < syncPollTimeout_s
        pause(syncPollInterval_s);
        syncWaited_s = syncWaited_s + syncPollInterval_s;
        syncRate_Hz  = double(detector.GetSyncRate());
        if syncRate_Hz > 0
            fprintf('%s sync rate detected after %.1f s: %.0f Hz\n', ...
                cfg.acquisition.device, syncWaited_s, syncRate_Hz);
        end
    end
    if syncRate_Hz <= 0
        error('%s sync rate is zero. Check the trigger cable and trigger waveform.', ...
            cfg.acquisition.device);
    end

    timing.syncRate_Hz                = syncRate_Hz;
    timing.syncPeriod_ns_fromDetector = 1e9 / syncRate_Hz;
    timing.histogramFinalBin = min( ...
        round(timing.sequenceDuration_ns * 1000 / detector.Resolution), 65536);

    if abs(timing.syncPeriod_ns_fromDetector - timing.sequenceDuration_ns) > ...
            cfg.analysis.syncPeriodTolerance_ns
        warning(['Measured %s sync period (%.3f ns) differs from the AWG sequence ' ...
            'period (%.3f ns).'], cfg.acquisition.device, ...
            timing.syncPeriod_ns_fromDetector, timing.sequenceDuration_ns);
    end

    results = acquireAndAnalyze(detector, timing, cfg, figures);
    results.cfg          = cfg;
    results.timing       = timing;
    results.detectorName = cfg.acquisition.device;

    fprintf('\nESR acquisition complete.\n');

    if cfg.output.saveResults
        saveMeasurementResults(results, figures, cfg);
    end
end

% -------------------------------------------------------------------------

function cfg = validateConfig(cfg)
    cfg.waveform.mwFrequencies_GHz = cfg.waveform.mwFrequencies_GHz(:).';

    if isempty(cfg.waveform.mwFrequencies_GHz)
        error('mwFrequencies_GHz cannot be empty.');
    end
    if any(cfg.waveform.mwFrequencies_GHz <= 0)
        error('All MW frequencies must be positive.');
    end
    if cfg.waveform.darkCountDuration_ns <= 0
        error('darkCountDuration_ns must be positive.');
    end
    if cfg.waveform.initPulseDuration_ns <= 0
        error('initPulseDuration_ns must be positive.');
    end
    if cfg.waveform.rotationPulseDuration_ns <= 0
        error('rotationPulseDuration_ns must be positive.');
    end
    if cfg.waveform.delayAfterRotation_ns < 0
        error('delayAfterRotation_ns must be non-negative.');
    end
    if cfg.waveform.readoutPulseDuration_ns <= 0
        error('readoutPulseDuration_ns must be positive.');
    end
    if cfg.awg.channelInit ~= 1 || cfg.awg.channelRot ~= 2 || cfg.awg.channelTrigger ~= 3
        error('AWG channels must be: Init = 1, Rotation = 2, Trigger = 3.');
    end
    if cfg.awg.initOnUserLevel <= cfg.awg.initOffUserLevel
        error('initPulseHeight must be larger than initOffUserLevel (0.5).');
    end
    if ~ismember(cfg.supply.initChannel, [1, 2, 3])
        error('initModulatorChannel must be 1, 2, or 3.');
    end
    if ~ismember(cfg.supply.rotChannel, [1, 2, 3])
        error('rotModulatorChannel must be 1, 2, or 3.');
    end
    if cfg.supply.initChannel == cfg.supply.rotChannel
        error('initModulatorChannel and rotModulatorChannel must be different.');
    end
    validDevices = {'Picoharp', 'TimeTagger'};
    if ~any(strcmpi(cfg.acquisition.device, validDevices))
        error('acquisitionDevice must be ''Picoharp'' or ''TimeTagger''.');
    end
    if strcmpi(cfg.acquisition.device, 'TimeTagger')
        if cfg.timetagger.triggerChannel == cfg.timetagger.photonChannel
            error('TimeTagger triggerChannel and photonChannel must be different.');
        end
    end
end

% -------------------------------------------------------------------------

function figures = createFigures(cfg)
    figures.histogram = figure('Name', [cfg.acquisition.device ' Histogram'], 'Color', 'w');
    clf(figures.histogram);
    axes('Parent', figures.histogram);
    hold on; box on;
    xlabel('Time (ns)');
    ylabel('Counts');
    title([cfg.acquisition.device ' Histogram']);

    figures.esr = figure('Name', 'ESR Spectrum', 'Color', 'w');
    clf(figures.esr);
    axes('Parent', figures.esr);
    hold on; box on;
    xlabel('MW frequency (GHz)');
    ylabel('Normalized signal');
    title('ESR Spectrum');

    figures.waveforms = [];
    if cfg.debug.plotWaveforms
        figures.waveforms = figure('Name', 'AWG Waveforms', 'Color', 'w');
        clf(figures.waveforms);
    end
end

% -------------------------------------------------------------------------

function detector = createDetectorHandle(cfg)
    if strcmpi(cfg.acquisition.device, 'Picoharp')
        detector = ClassPicoharp.getInstance();
    else
        detector = ClassTimeTagger.getInstance();
    end
end

% -------------------------------------------------------------------------

function connectAndConfigureInstruments(awg, detector, supply, cfg)
    try awg.CloseConnection();      catch; end
    try detector.CloseConnection(); catch; end
    try supply.disconnect();        catch; end

    awg.connect(2);  % DCM mode: Ch1=Init (analog), Ch2=Rotation (analog), Ch3=Marker1 (trigger)
    awg.SetChannels({'Initialization', 'Rotation', 'Trigger', ''}, 1:4, ...
        cfg.awg.userDelays_ns);

    % Ch3 is Marker1 in DCM mode. The AWG accepts :VOLT3:LEV:IMM:AMPL/OFFS for
    % marker channels and uses them to derive HIGH = offset + amp/2, LOW = offset - amp/2.
    triggerAmplitude_V = cfg.awg.triggerHighVoltage_V - cfg.awg.triggerLowVoltage_V;
    triggerOffset_V    = (cfg.awg.triggerHighVoltage_V + cfg.awg.triggerLowVoltage_V) / 2;
    awg.SetAmpl(cfg.awg.channelTrigger, triggerAmplitude_V);
    awg.SetOffset(cfg.awg.channelTrigger, triggerOffset_V);

    detector.connect();
    detector.SetTimeStop(cfg.acquisition.time_s);
    detector.SetResolution(cfg.acquisition.resolution_ps);

    if strcmpi(cfg.acquisition.device, 'Picoharp')
        detector.SetOffset(cfg.picoharp.histogramOffset_ps);
        detector.SetZeroOffset0(cfg.picoharp.syncOffset_ps);
        detector.SetZeroDiscr0(cfg.picoharp.syncDiscriminator_mV);
        detector.SetZeroCr0(cfg.picoharp.syncZeroCross_mV);
        detector.SetZeroDiscr1(cfg.picoharp.signalDiscriminator_mV);
        detector.SetZeroCr1(cfg.picoharp.signalZeroCross_mV);
        detector.SetCountStop(cfg.picoharp.countStop);
    else
        detector.SetChannels(cfg.timetagger.triggerChannel, cfg.timetagger.photonChannel);
        detector.SetTriggerLevels(cfg.timetagger.triggerChannel, cfg.timetagger.triggerLevel_V);
        detector.SetTriggerLevels(cfg.timetagger.photonChannel,  cfg.timetagger.photonLevel_V);
    end

    supply.connect('TriplePowerSupply');
    supply.setCurrent(cfg.supply.currentLimit_A, cfg.supply.initChannel);
    supply.setVoltage(cfg.supply.initVoltage_V,  cfg.supply.initChannel);
    supply.powerOn(cfg.supply.initChannel);
    supply.setCurrent(cfg.supply.currentLimit_A, cfg.supply.rotChannel);
    supply.setVoltage(cfg.supply.rotVoltage_V,   cfg.supply.rotChannel);
    supply.powerOn(cfg.supply.rotChannel);
    pause(cfg.supply.settleTime_s);
end

% -------------------------------------------------------------------------

function prepareDetectorForSequence(detector, timing, cfg)
    if strcmpi(cfg.acquisition.device, 'TimeTagger')
        numBins = max(round(timing.sequenceDuration_ns * 1000 / ...
            cfg.acquisition.resolution_ps), 1);
        detector.SetNumBins(numBins);
    end
end

% -------------------------------------------------------------------------

function reportDetectorRates(detector, cfg)
    pause(0.2);
    if strcmpi(cfg.acquisition.device, 'Picoharp')
        syncRate_Hz   = double(detector.GetSyncRate());
        signalRate_Hz = double(detector.ReadCounter(1));
        fprintf('PicoHarp sync rate:   %.0f Hz\n', syncRate_Hz);
        fprintf('PicoHarp signal rate: %.0f Hz\n', signalRate_Hz);
    else
        triggerRate_Hz = double(detector.ReadCounter(cfg.timetagger.triggerChannel));
        photonRate_Hz  = double(detector.ReadCounter(cfg.timetagger.photonChannel));
        fprintf('TimeTagger trigger rate (channel %d): %.0f Hz\n', ...
            cfg.timetagger.triggerChannel, triggerRate_Hz);
        fprintf('TimeTagger photon  rate (channel %d): %.0f Hz\n', ...
            cfg.timetagger.photonChannel,  photonRate_Hz);
    end
end

% -------------------------------------------------------------------------

function timing = buildAndRunSequence(awg, cfg, figures)
    N = numel(cfg.waveform.mwFrequencies_GHz);

    if cfg.waveform.isRandomized
        sweepOrder = randperm(N);
    else
        sweepOrder = 1:N;
    end

    segmentDuration_ns = cfg.waveform.darkCountDuration_ns     + ...
                         cfg.waveform.initPulseDuration_ns      + ...
                         cfg.waveform.rotationPulseDuration_ns  + ...
                         cfg.waveform.delayAfterRotation_ns     + ...
                         cfg.waveform.readoutPulseDuration_ns;
    totalDuration_ns = N * segmentDuration_ns;

    [ch1EndTimes, ch1Types, ch1Params, darkStarts, initStarts, readoutStarts] = ...
        buildInitReadoutSections(cfg, sweepOrder);
    ch1Waveform = awg.CreateWaveform(ch1EndTimes, ch1Types, ch1Params, cfg.awg.channelInit);

    [ch2EndTimes, ch2Types, ch2Params] = buildRotationSections(cfg, sweepOrder);
    ch2Waveform = awg.CreateWaveform(ch2EndTimes, ch2Types, ch2Params, cfg.awg.channelRot);

    [ch3EndTimes, ch3Types, ch3Params] = buildTriggerSections(totalDuration_ns, cfg);
    ch3Waveform = awg.CreateWaveform(ch3EndTimes, ch3Types, ch3Params, cfg.awg.channelTrigger);

    segment = cell(1, 4);
    segment{cfg.awg.channelInit}    = ch1Waveform;
    segment{cfg.awg.channelRot}     = ch2Waveform;
    segment{cfg.awg.channelTrigger} = ch3Waveform;
    awg.RunSegment(segment);

    maxSamples = max([numel(ch1Waveform), numel(ch2Waveform), numel(ch3Waveform)]);

    timing.sequenceDuration_ns    = awg.AWGStep * maxSamples;
    timing.segmentDuration_ns     = segmentDuration_ns;
    timing.N                      = N;
    timing.sweepOrder             = sweepOrder;
    timing.mwFrequencies_GHz      = cfg.waveform.mwFrequencies_GHz;
    timing.darkWindowStarts_ns    = round(darkStarts    / awg.AWGStep) * awg.AWGStep;
    timing.initWindowStarts_ns    = round(initStarts    / awg.AWGStep) * awg.AWGStep;
    timing.readoutWindowStarts_ns = round(readoutStarts / awg.AWGStep) * awg.AWGStep;
    timing.darkWindowDuration_ns    = cfg.waveform.darkCountDuration_ns;
    timing.initWindowDuration_ns    = cfg.waveform.initPulseDuration_ns;
    timing.readoutWindowDuration_ns = cfg.waveform.readoutPulseDuration_ns;
    timing.histogramFinalBin = min( ...
        round(timing.sequenceDuration_ns * 1000 / cfg.acquisition.resolution_ps), 65536);

    if cfg.debug.plotWaveforms
        plotCreatedWaveforms(figures.waveforms, ch1Waveform, ch2Waveform, ch3Waveform, ...
            timing, awg, cfg);
    end
end

% -------------------------------------------------------------------------

function [endTimes, types, params, darkStarts, initStarts, readoutStarts] = ...
        buildInitReadoutSections(cfg, sweepOrder)
    N          = numel(sweepOrder);
    endTimes   = [];
    types      = {};
    params     = {};

    darkStarts    = zeros(1, N);
    initStarts    = zeros(1, N);
    readoutStarts = zeros(1, N);

    currentTime_ns = 0;

    for k = 1:N
        % Dark-count window (Ch1 off)
        darkStarts(k) = currentTime_ns;
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.darkCountDuration_ns, cfg.awg.initOffUserLevel);

        % Initialization pulse (Ch1 on)
        initStarts(k) = currentTime_ns;
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.initPulseDuration_ns, cfg.awg.initOnUserLevel);

        % Ch1 off during rotation window + post-rotation delay
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.rotationPulseDuration_ns + cfg.waveform.delayAfterRotation_ns, ...
            cfg.awg.initOffUserLevel);

        % Readout pulse (Ch1 on)
        readoutStarts(k) = currentTime_ns;
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.readoutPulseDuration_ns, cfg.awg.initOnUserLevel);
    end
end

% -------------------------------------------------------------------------

function [endTimes, types, params] = buildRotationSections(cfg, sweepOrder)
    N          = numel(sweepOrder);
    endTimes   = [];
    types      = {};
    params     = {};

    currentTime_ns = 0;

    for k = 1:N
        freq_GHz = cfg.waveform.mwFrequencies_GHz(sweepOrder(k));

        % Ch2 off during dark-count window and init pulse
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.darkCountDuration_ns + cfg.waveform.initPulseDuration_ns, 0);

        % MW rotation sine pulse
        currentTime_ns    = currentTime_ns + cfg.waveform.rotationPulseDuration_ns;
        endTimes(end + 1) = currentTime_ns;                     %#ok<AGROW>
        types{end + 1}    = 'sine';                             %#ok<AGROW>
        params{end + 1}   = struct( ...                         %#ok<AGROW>
            'Amplitude', cfg.awg.rotationAmplitude, ...
            'Frequency', freq_GHz, ...
            'Phase',     0, ...
            'Frame',     cfg.awg.rotationFrame, ...
            'Offset',    0);

        % Ch2 off during post-rotation delay and readout pulse
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, ...
            cfg.waveform.delayAfterRotation_ns + cfg.waveform.readoutPulseDuration_ns, 0);
    end
end

% -------------------------------------------------------------------------

function [endTimes, types, params] = buildTriggerSections(totalDuration_ns, cfg)
    endTimes = [];
    types    = {};
    params   = {};

    if strcmpi(cfg.acquisition.device, 'TimeTagger')
        activeLevel   =  1;  % marker HIGH  → TimeTagger sees rising edge
        inactiveLevel =  0;  % marker LOW   — must be 0, not -1, for M8195A marker encoding
    else  % Picoharp — active low
        activeLevel   =  0;  % marker LOW   → Picoharp active-low trigger fires
        inactiveLevel =  1;  % marker HIGH  — must be 0/1 for correct marker bit packing
    end

    activeEnd_ns = totalDuration_ns / 2;

    endTimes(end + 1)      = activeEnd_ns;    %#ok<AGROW>
    types{end + 1}         = 'dc';            %#ok<AGROW>
    params{end + 1}.Offset = activeLevel;     %#ok<AGROW>

    if activeEnd_ns < totalDuration_ns
        endTimes(end + 1)      = totalDuration_ns; %#ok<AGROW>
        types{end + 1}         = 'dc';             %#ok<AGROW>
        params{end + 1}.Offset = inactiveLevel;    %#ok<AGROW>
    end
end

% -------------------------------------------------------------------------

function [endTimes, types, params, currentTime_ns] = appendDcSection( ...
        endTimes, types, params, currentTime_ns, duration_ns, level)
    if duration_ns <= 0
        return;
    end
    currentTime_ns       = currentTime_ns + duration_ns;
    endTimes(end + 1)    = currentTime_ns; %#ok<AGROW>
    types{end + 1}       = 'dc';           %#ok<AGROW>
    params{end + 1}.Offset = level;        %#ok<AGROW>
end

% -------------------------------------------------------------------------

function results = acquireAndAnalyze(detector, timing, cfg, figures)
    figure(figures.histogram);
    histogramPlot = plot(nan, nan, 'b-', 'LineWidth', 1.2);

    figure(figures.esr);
    dataPlot = plot(nan, nan, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);

    detector.StartAcquisition();

    while ~detector.CheckAquisitionDone()
        loopTimer = tic;
        [timeAxis_ns, histogram] = detector.GetHistogram();
        analysis = analyzeHistogram(histogram, timing, detector.Resolution, true);
        updatePlots(histogramPlot, dataPlot, timeAxis_ns, histogram, analysis, timing);
        pause(max(cfg.acquisition.pollPeriod_s - toc(loopTimer), 0));
    end

    [timeAxis_ns, histogram] = detector.GetHistogram();
    analysis = analyzeHistogram(histogram, timing, detector.Resolution, false);
    updatePlots(histogramPlot, dataPlot, timeAxis_ns, histogram, analysis, timing);
    detector.StopAcquisition();

    results.timeAxis_ns       = timeAxis_ns;
    results.histogram         = histogram;
    results.darkCounts        = analysis.darkCounts;
    results.initCounts        = analysis.initCounts;
    results.readoutCounts     = analysis.readoutCounts;
    results.normalizedSignal  = analysis.normalizedSignal;
    results.mwFrequencies_GHz = timing.mwFrequencies_GHz;
end

% -------------------------------------------------------------------------

function analysis = analyzeHistogram(histogram, timing, resolution_ps, allowEmptyReference)
    if nargin < 4
        allowEmptyReference = false;
    end

    histogram = double(histogram(:));
    finalBin  = min(timing.histogramFinalBin, numel(histogram));

    N             = timing.N;
    darkCounts    = zeros(1, N);
    initCounts    = zeros(1, N);
    readoutCounts = zeros(1, N);

    for k = 1:N
        darkCounts(k) = integrateWindow(histogram, timing.darkWindowStarts_ns(k), ...
            timing.darkWindowDuration_ns, resolution_ps, finalBin);
        initCounts(k) = integrateWindow(histogram, timing.initWindowStarts_ns(k), ...
            timing.initWindowDuration_ns, resolution_ps, finalBin);
        readoutCounts(k) = integrateWindow(histogram, timing.readoutWindowStarts_ns(k), ...
            timing.readoutWindowDuration_ns, resolution_ps, finalBin);
    end

    correctedInit    = initCounts    - darkCounts;
    correctedReadout = readoutCounts - darkCounts;

    if all(correctedInit <= 0)
        if allowEmptyReference
            normalizedSignal = nan(1, N);
            analysis.darkCounts       = darkCounts;
            analysis.initCounts       = initCounts;
            analysis.readoutCounts    = readoutCounts;
            analysis.normalizedSignal = normalizedSignal;
            return;
        end
        error(['All init pulse counts are not above the dark-count background after the ' ...
            'full acquisition.  Check the initialization pulse, detector trigger settings, ' ...
            'and photon-arrival timing.']);
    end

    % Normalize readout by init, per segment
    normalizedSignal_bySeq = zeros(1, N);
    for k = 1:N
        if correctedInit(k) > 0
            normalizedSignal_bySeq(k) = correctedReadout(k) / correctedInit(k);
        else
            normalizedSignal_bySeq(k) = NaN;
        end
    end

    % Map from sequence order back to frequency order for plotting
    normalizedSignal                    = zeros(1, N);
    normalizedSignal(timing.sweepOrder) = normalizedSignal_bySeq;

    analysis.darkCounts       = darkCounts;
    analysis.initCounts       = initCounts;
    analysis.readoutCounts    = readoutCounts;
    analysis.normalizedSignal = normalizedSignal;
end

% -------------------------------------------------------------------------

function counts = integrateWindow(histogram, startTime_ns, duration_ns, resolution_ps, finalBin)
    startBinZeroBased = round(startTime_ns * 1000 / resolution_ps);
    binCount = max(round(duration_ns * 1000 / resolution_ps), 1);
    indices  = mod(startBinZeroBased + (0:binCount - 1), finalBin) + 1;
    counts   = sum(histogram(indices));
end

% -------------------------------------------------------------------------

function updatePlots(histogramPlot, dataPlot, timeAxis_ns, histogram, analysis, timing)
    set(histogramPlot, ...
        'XData', timeAxis_ns(1:timing.histogramFinalBin), ...
        'YData', histogram(1:timing.histogramFinalBin));

    set(dataPlot, ...
        'XData', timing.mwFrequencies_GHz, ...
        'YData', analysis.normalizedSignal);

    figure(ancestor(histogramPlot, 'figure'));
    title('Histogram');

    figure(ancestor(dataPlot, 'figure'));
    title('ESR Spectrum');

    drawnow;
end

% -------------------------------------------------------------------------

function plotCreatedWaveforms(figHandle, ch1Waveform, ch2Waveform, ch3Waveform, ...
        timing, awg, cfg)
    figure(figHandle);
    clf(figHandle);

    totalSamples = max([numel(ch1Waveform), numel(ch2Waveform), numel(ch3Waveform)]);
    timeAxis_ns  = (0:totalSamples - 1) * awg.AWGStep;

    ch1Waveform = padWaveformForPlot(ch1Waveform, totalSamples);
    ch2Waveform = padWaveformForPlot(ch2Waveform, totalSamples);
    ch3Waveform = padWaveformForPlot(ch3Waveform, totalSamples);

    % Approximate output voltages for visualization
    initAmplitude_Vpp = awg.MaxAmpForInitialization;
    ch1Output_V = initAmplitude_Vpp / 2 + 0.5 * initAmplitude_Vpp * ch1Waveform;

    rotAmplitude_Vpp = awg.MaxAmp;  % Ch2 hardware amplitude set by connect() via :VOLT2:AMPL MaxAmp
    ch2Output_V = 0.5 * rotAmplitude_Vpp * ch2Waveform;

    trigAmplitude_V = cfg.awg.triggerHighVoltage_V - cfg.awg.triggerLowVoltage_V;
    trigOffset_V    = (cfg.awg.triggerHighVoltage_V + cfg.awg.triggerLowVoltage_V) / 2;
    ch3Output_V = trigOffset_V + 0.5 * trigAmplitude_V * ch3Waveform;

    ax1 = subplot(3, 1, 1, 'Parent', figHandle);
    stairs(ax1, timeAxis_ns, ch1Output_V, 'b-', 'LineWidth', 1.0);
    ylabel(ax1, 'Init (V)');
    title(ax1, 'Uploaded AWG Waveforms');
    grid(ax1, 'on');
    xlim(ax1, [0, timing.sequenceDuration_ns]);

    ax2 = subplot(3, 1, 2, 'Parent', figHandle);
    plot(ax2, timeAxis_ns, ch2Output_V, 'g-', 'LineWidth', 0.8);
    ylabel(ax2, 'Rotation (V)');
    grid(ax2, 'on');
    xlim(ax2, [0, timing.sequenceDuration_ns]);

    ax3 = subplot(3, 1, 3, 'Parent', figHandle);
    stairs(ax3, timeAxis_ns, ch3Output_V, 'r-', 'LineWidth', 1.0);
    xlabel(ax3, 'Time (ns)');
    ylabel(ax3, 'Trigger (V)');
    grid(ax3, 'on');
    xlim(ax3, [0, timing.sequenceDuration_ns]);

    linkaxes([ax1, ax2, ax3], 'x');
    drawnow;
end

% -------------------------------------------------------------------------

function waveform = padWaveformForPlot(waveform, targetLength)
    if numel(waveform) >= targetLength
        waveform = waveform(1:targetLength);
        return;
    end
    if isempty(waveform)
        waveform = zeros(1, targetLength);
        return;
    end
    waveform(end + 1:targetLength) = waveform(end);
end

% -------------------------------------------------------------------------

function saveMeasurementResults(results, figures, cfg)
    if isempty(cfg.output.baseFileName)
        baseName = ['ESR_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))];
    else
        baseName = cfg.output.baseFileName;
    end

    if ~exist(cfg.output.outputFolder, 'dir')
        mkdir(cfg.output.outputFolder);
    end

    save(fullfile(cfg.output.outputFolder, [baseName '.mat']), 'results');
    saveas(figures.histogram, fullfile(cfg.output.outputFolder, [baseName '_histogram.png']));
    saveas(figures.esr,       fullfile(cfg.output.outputFolder, [baseName '_esr.png']));
end

% -------------------------------------------------------------------------

function cleanupInstruments(awg, detector, supply, cfg)
    if cfg.cleanup.turnOutputsOff
        try
            if ~isempty(awg)
                awg.ChannelsOff();
            end
        catch
        end
        try
            if ~isempty(supply)
                supply.powerOff(cfg.supply.initChannel);
                supply.powerOff(cfg.supply.rotChannel);
            end
        catch
        end
    end

    if cfg.cleanup.disconnectInstruments
        try
            if ~isempty(detector)
                detector.StopAcquisition();
            end
        catch
        end
        try
            if ~isempty(detector)
                detector.CloseConnection();
            end
        catch
        end
        try
            if ~isempty(awg)
                awg.CloseConnection();
            end
        catch
        end
        try
            if ~isempty(supply)
                supply.disconnect();
            end
        catch
        end
    end
end
