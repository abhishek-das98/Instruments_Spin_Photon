% MeasureT1.m
% Edit the settings in this block, then press Run.

biasVoltage_V = 2.97;              % Edit it to have minimum optical power when RF voltage is 0
powerSupplyChannel = 2;            % Keysight triple supply channel: 1, 2, or 3
initializationPulseHeight = 1.00;  % User AWG level for the initialization pulse.
waitTimes_ns = 5:5:100;            % Free Evolution time Array

picoharpTriggerLowVoltage_V = -0.5;
picoharpTriggerHighVoltage_V = 0.0;
timetaggerTriggerLowVoltage_V = 0.0;
timetaggerTriggerHighVoltage_V = 1.0;

darkCountDuration_ns = 5;
initializationPulseDuration_ns = 8;
finalWait_ns = [];  % Leave empty to use 2*max(waitTimes_ns).
awgUserDelays_ns = [0, 0, 0, 0];  % [Initialization, Trigger, channel 3, channel 4]

acquisitionDevice = 'TimeTagger';  % 'Picoharp' or 'TimeTagger'
acquisitionTime_s = 30;
binResolution_ps = 512;
plotWaveforms = true;


shouldSaveResults = false;
outputFolder = ['/Users/abhishekdas/Library/CloudStorage/OneDrive-NorthCarolinaStateUniversity/' ...
    '    HardwareStuff/Results'];
baseFileName = 'Experiment_T1_Practice';

cfg.waveform.darkCountDuration_ns = darkCountDuration_ns;
cfg.waveform.initDuration_ns = initializationPulseDuration_ns;
cfg.waveform.waitTimes_ns = waitTimes_ns;
cfg.waveform.finalWait_ns = finalWait_ns;

cfg.awg.channelInitialization = 1;
cfg.awg.channelTrigger = 2;
cfg.awg.userDelays_ns = awgUserDelays_ns;
cfg.awg.initOnUserLevel = initializationPulseHeight;
cfg.awg.initOffUserLevel = 0.5;  % Internal AWG level that gives 0 V in your setup.
cfg.awg.settleTime_s = 0.5;

cfg.acquisition.device = acquisitionDevice;
cfg.acquisition.time_s = acquisitionTime_s;
cfg.acquisition.resolution_ps = binResolution_ps;
cfg.acquisition.pollPeriod_s = 0.25;


cfg.picoharp.histogramOffset_ps = 0;
cfg.picoharp.syncOffset_ps = 0;
cfg.picoharp.syncDiscriminator_mV = 50;
cfg.picoharp.syncZeroCross_mV = 10;
cfg.picoharp.signalDiscriminator_mV = 50;
cfg.picoharp.signalZeroCross_mV = 10;
cfg.picoharp.countStop = 65535;


cfg.timetagger.triggerChannel = 1;
cfg.timetagger.photonChannel = 2;
cfg.timetagger.triggerLevel_V = 0.10;
cfg.timetagger.photonLevel_V = 0.05;

cfg.supply.biasVoltage_V = biasVoltage_V;
cfg.supply.currentLimit_A = 0.01;
cfg.supply.channel = powerSupplyChannel;
cfg.supply.settleTime_s = 0.25;

cfg.analysis.integrationWindow_ns = initializationPulseDuration_ns;
cfg.analysis.backgroundWindowStart_ns = 0;
cfg.analysis.backgroundWindowDuration_ns = darkCountDuration_ns;
cfg.analysis.syncPeriodTolerance_ns = 2.0;

cfg.output.saveResults = shouldSaveResults;
cfg.output.outputFolder = outputFolder;
cfg.output.baseFileName = baseFileName;

cfg.debug.plotWaveforms = plotWaveforms;

cfg.cleanup.turnOutputsOff = true;
cfg.cleanup.disconnectInstruments = true;

if strcmpi(cfg.acquisition.device, 'Picoharp')
    cfg.awg.triggerLowVoltage_V = picoharpTriggerLowVoltage_V;
    cfg.awg.triggerHighVoltage_V = picoharpTriggerHighVoltage_V;
else
    cfg.awg.triggerLowVoltage_V = timetaggerTriggerLowVoltage_V;
    cfg.awg.triggerHighVoltage_V = timetaggerTriggerHighVoltage_V;
end

results = runMeasureT1Internal(cfg);

function results = runMeasureT1Internal(cfg)
    cfg = validateConfig(cfg);
    addpath(fileparts(mfilename('fullpath')));

    awg = [];
    detector = [];
    supply = [];
    cleanupObj = onCleanup(@() cleanupInstruments(awg, detector, supply, cfg)); %#ok<NASGU>

    figures = createFigures(cfg);

    awg = ClassAWG.getInstance();
    detector = createDetectorHandle(cfg);
    supply = ClassKeysightSupply.getInstance();

    connectAndConfigureInstruments(awg, detector, supply, cfg);
    timing = buildAndRunSequence(awg, cfg, figures);
    prepareDetectorForSequence(detector, timing, cfg);
    reportDetectorRates(detector, cfg);

    pause(cfg.awg.settleTime_s);
    syncRate_Hz = double(detector.GetSyncRate());
    if syncRate_Hz <= 0
        error('%s sync rate is zero. Check the trigger cable and trigger waveform.', cfg.acquisition.device);
    end

    timing.syncRate_Hz = syncRate_Hz;
    timing.syncPeriod_ns_fromDetector = 1e9 / syncRate_Hz;
    timing.histogramFinalBin = min(round(timing.sequenceDuration_ns * 1000 / detector.Resolution), 65536);

    if abs(timing.syncPeriod_ns_fromDetector - timing.sequenceDuration_ns) > cfg.analysis.syncPeriodTolerance_ns
        warning(['Measured %s sync period (%.3f ns) differs from the AWG sequence period ' ...
            '(%.3f ns). Using the AWG period for integration.'], ...
            cfg.acquisition.device, timing.syncPeriod_ns_fromDetector, timing.sequenceDuration_ns);
    end

    results = acquireAndFit(detector, timing, cfg, figures);
    results.cfg = cfg;
    results.timing = timing;
    results.detectorName = cfg.acquisition.device;

    fprintf('\nExtracted T1 = %.3f ns\n', results.fit.T1_ns);

    if cfg.output.saveResults
        saveMeasurementResults(results, figures, cfg);
    end
end

function cfg = validateConfig(cfg)
    cfg.waveform.waitTimes_ns = cfg.waveform.waitTimes_ns(:).';

    if isempty(cfg.waveform.waitTimes_ns)
        error('waitTimes_ns cannot be empty.');
    end

    if any(cfg.waveform.waitTimes_ns <= 0)
        error('All wait times must be positive.');
    end

    if isempty(cfg.waveform.finalWait_ns)
        cfg.waveform.finalWait_ns = 2 * max(cfg.waveform.waitTimes_ns);
    end

    if cfg.awg.channelInitialization ~= 1 || cfg.awg.channelTrigger ~= 2
        error('Use AWG channel 1 for initialization and channel 2 for trigger.');
    end

    if cfg.awg.initOnUserLevel <= cfg.awg.initOffUserLevel
        error('initializationPulseHeight must be larger than the internal off level of 0.5.');
    end

    if ~ismember(cfg.supply.channel, [1, 2, 3])
        error('powerSupplyChannel must be 1, 2, or 3.');
    end

    validDevices = {'Picoharp', 'TimeTagger'};
    if ~any(strcmpi(cfg.acquisition.device, validDevices))
        error('acquisitionDevice must be ''Picoharp'' or ''TimeTagger''.');
    end

    if cfg.timetagger.triggerChannel == cfg.timetagger.photonChannel
        error('TimeTagger triggerChannel and photonChannel must be different.');
    end
end

function figures = createFigures(cfg)
    figures.histogram = figure('Name', [cfg.acquisition.device ' Histogram'], 'Color', 'w');
    clf(figures.histogram);
    axes('Parent', figures.histogram);
    hold on;
    box on;
    xlabel('Time (ns)');
    ylabel('Counts');
    title([cfg.acquisition.device ' Histogram']);

    figures.t1 = figure('Name', 'T1 Fit', 'Color', 'w');
    clf(figures.t1);
    axes('Parent', figures.t1);
    hold on;
    box on;
    xlabel('Wait time (ns)');
    ylabel('Normalized signal');
    title('T1 Extraction');

    figures.waveforms = [];
    if cfg.debug.plotWaveforms
        figures.waveforms = figure('Name', 'AWG Waveforms', 'Color', 'w');
        clf(figures.waveforms);
    end
end

function detector = createDetectorHandle(cfg)
    if strcmpi(cfg.acquisition.device, 'Picoharp')
        detector = ClassPicoharp.getInstance();
    else
        detector = ClassTimeTagger.getInstance();
    end
end

function connectAndConfigureInstruments(awg, detector, supply, cfg)
    try
        awg.CloseConnection();
    catch
    end

    try
        detector.CloseConnection();
    catch
    end

    try
        supply.disconnect();
    catch
    end

    awg.connect(2);
    awg.SetChannels({'Initialization', 'Trigger', '', ''}, 1:4, cfg.awg.userDelays_ns);

    triggerAmplitude_V = cfg.awg.triggerHighVoltage_V - cfg.awg.triggerLowVoltage_V;
    triggerOffset_V = (cfg.awg.triggerHighVoltage_V + cfg.awg.triggerLowVoltage_V) / 2;
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
        detector.SetTriggerLevels(cfg.timetagger.photonChannel, cfg.timetagger.photonLevel_V);
    end

    supply.connect('TriplePowerSupply');
    supply.setCurrent(cfg.supply.currentLimit_A, cfg.supply.channel);
    supply.setVoltage(cfg.supply.biasVoltage_V, cfg.supply.channel);
    supply.powerOn(cfg.supply.channel);
    pause(cfg.supply.settleTime_s);
end

function prepareDetectorForSequence(detector, timing, cfg)
    if strcmpi(cfg.acquisition.device, 'TimeTagger')
        detector.SetNumBins(max(round(timing.sequenceDuration_ns * 1000 / cfg.acquisition.resolution_ps), 1));
    end
end

function reportDetectorRates(detector, cfg)
    pause(0.2);

    if strcmpi(cfg.acquisition.device, 'Picoharp')
        syncRate_Hz = double(detector.GetSyncRate());
        signalRate_Hz = double(detector.ReadCounter(1));

        fprintf('PicoHarp sync rate: %.0f Hz\n', syncRate_Hz);
        fprintf('PicoHarp signal rate: %.0f Hz\n', signalRate_Hz);
    else
        triggerRate_Hz = double(detector.ReadCounter(cfg.timetagger.triggerChannel));
        photonRate_Hz = double(detector.ReadCounter(cfg.timetagger.photonChannel));

        fprintf('TimeTagger trigger rate (channel %d): %.0f Hz\n', ...
            cfg.timetagger.triggerChannel, triggerRate_Hz);
        fprintf('TimeTagger photon rate (channel %d): %.0f Hz\n', ...
            cfg.timetagger.photonChannel, photonRate_Hz);
    end
end

function timing = buildAndRunSequence(awg, cfg, figures)
    [initEndTimes, initTypes, initParams, pulseStartTimes_ns, requestedSequenceDuration_ns] = buildInitializationSections(cfg);
    initWaveform = awg.CreateWaveform(initEndTimes, initTypes, initParams, cfg.awg.channelInitialization);

    [triggerEndTimes, triggerTypes, triggerParams] = buildTriggerSections( ...
        requestedSequenceDuration_ns, pulseStartTimes_ns(1), cfg);
    triggerWaveform = awg.CreateWaveform(triggerEndTimes, triggerTypes, triggerParams, cfg.awg.channelTrigger);

    segment = cell(1, 4);
    segment{cfg.awg.channelInitialization} = initWaveform;
    segment{cfg.awg.channelTrigger} = triggerWaveform;

    awg.RunSegment(segment);

    timing.sequenceDuration_ns = awg.AWGStep * max([numel(initWaveform), numel(triggerWaveform)]);
    timing.pulseStartTimes_ns = round(pulseStartTimes_ns / awg.AWGStep) * awg.AWGStep;
    timing.waitTimes_ns = cfg.waveform.waitTimes_ns;
    timing.integrationWindow_ns = cfg.analysis.integrationWindow_ns;
    timing.backgroundWindowStart_ns = cfg.analysis.backgroundWindowStart_ns;
    timing.backgroundWindowDuration_ns = cfg.analysis.backgroundWindowDuration_ns;

    if cfg.debug.plotWaveforms
        plotCreatedWaveforms(figures.waveforms, initWaveform, triggerWaveform, timing, awg, cfg);
    end
end

function [endTimes, types, params, pulseStartTimes_ns, totalTime_ns] = buildInitializationSections(cfg)
    endTimes = [];
    types = {};
    params = {};
    pulseStartTimes_ns = zeros(1, numel(cfg.waveform.waitTimes_ns) + 1);
    currentTime_ns = 0;

    [endTimes, types, params, currentTime_ns] = appendDcSection( ...
        endTimes, types, params, currentTime_ns, cfg.waveform.darkCountDuration_ns, cfg.awg.initOffUserLevel);

    for k = 1:numel(cfg.waveform.waitTimes_ns)
        pulseStartTimes_ns(k) = currentTime_ns;
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, cfg.waveform.initDuration_ns, cfg.awg.initOnUserLevel);
        [endTimes, types, params, currentTime_ns] = appendDcSection( ...
            endTimes, types, params, currentTime_ns, cfg.waveform.waitTimes_ns(k), cfg.awg.initOffUserLevel);
    end

    pulseStartTimes_ns(end) = currentTime_ns;
    [endTimes, types, params, currentTime_ns] = appendDcSection( ...
        endTimes, types, params, currentTime_ns, cfg.waveform.initDuration_ns, cfg.awg.initOnUserLevel);
    [endTimes, types, params, currentTime_ns] = appendDcSection( ...
        endTimes, types, params, currentTime_ns, cfg.waveform.finalWait_ns, cfg.awg.initOffUserLevel);

    totalTime_ns = currentTime_ns;
end

function [endTimes, types, params] = buildTriggerSections(sequenceDuration_ns, firstPulseStart_ns, cfg)
    activeStart_ns = 0;
    activeEnd_ns = min(firstPulseStart_ns + sequenceDuration_ns / 2, sequenceDuration_ns);

    endTimes = [];
    types = {};
    params = {};

    if strcmpi(cfg.acquisition.device, 'TimeTagger')
        inactiveLevel = -1;
        activeLevel = 1;
    else
        inactiveLevel = 1;
        activeLevel = -1;
    end

    % Keep the trigger in its active state from the start of the sequence,
    % including the dark-count window.
    endTimes(end + 1) = activeEnd_ns; %#ok<AGROW>
    types{end + 1} = 'dc'; %#ok<AGROW>
    params{end + 1}.Offset = activeLevel; %#ok<AGROW>

    if activeEnd_ns < sequenceDuration_ns
        % Return to the baseline trigger level for the second half of the sequence.
        endTimes(end + 1) = sequenceDuration_ns; %#ok<AGROW>
        types{end + 1} = 'dc'; %#ok<AGROW>
        params{end + 1}.Offset = inactiveLevel; %#ok<AGROW>
    end
end

function [endTimes, types, params, currentTime_ns] = appendDcSection(endTimes, types, params, currentTime_ns, duration_ns, level)
    if duration_ns <= 0
        return;
    end

    currentTime_ns = currentTime_ns + duration_ns;
    endTimes(end + 1) = currentTime_ns; %#ok<AGROW>
    types{end + 1} = 'dc'; %#ok<AGROW>
    params{end + 1}.Offset = level; %#ok<AGROW>
end

function results = acquireAndFit(detector, timing, cfg, figures)
    figure(figures.histogram);
    histogramPlot = plot(nan, nan, 'b-', 'LineWidth', 1.2);

    figure(figures.t1);
    dataPlot = plot(nan, nan, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Data');
    fitPlot = plot(nan, nan, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Fit');
    legend('Location', 'best');

    detector.StartAcquisition();

    while ~detector.CheckAquisitionDone()
        loopTimer = tic;
        [timeAxis_ns, histogram] = detector.GetHistogram();
        analysis = analyzeHistogram(histogram, timing, detector.Resolution, true);
        updatePlots(histogramPlot, dataPlot, fitPlot, timeAxis_ns, histogram, analysis, timing);
        pause(max(cfg.acquisition.pollPeriod_s - toc(loopTimer), 0));
    end

    [timeAxis_ns, histogram] = detector.GetHistogram();
    analysis = analyzeHistogram(histogram, timing, detector.Resolution, false);
    updatePlots(histogramPlot, dataPlot, fitPlot, timeAxis_ns, histogram, analysis, timing);
    detector.StopAcquisition();

    results.timeAxis_ns = timeAxis_ns;
    results.histogram = histogram;
    results.pulseCounts = analysis.pulseCounts;
    results.backgroundCounts = analysis.backgroundCount;
    results.normalizedSignal = analysis.normalizedSignal;
    results.correctedPulseCounts = analysis.correctedPulseCounts;
    results.fit = analysis.fit;
end

function analysis = analyzeHistogram(histogram, timing, resolution_ps, allowEmptyReference)
    if nargin < 4
        allowEmptyReference = false;
    end

    histogram = double(histogram(:));
    finalBin = min(timing.histogramFinalBin, numel(histogram));

    pulseCounts = zeros(1, numel(timing.pulseStartTimes_ns));
    for k = 1:numel(timing.pulseStartTimes_ns)
        pulseCounts(k) = integrateWindow(histogram, timing.pulseStartTimes_ns(k), ...
            timing.integrationWindow_ns, resolution_ps, finalBin);
    end

    backgroundCount = integrateWindow(histogram, timing.backgroundWindowStart_ns, ...
        timing.backgroundWindowDuration_ns, resolution_ps, finalBin);

    correctedPulseCounts = pulseCounts - backgroundCount;
    referenceCount = correctedPulseCounts(1);
    if referenceCount <= 0
        if allowEmptyReference
            normalizedSignal = nan(size(timing.waitTimes_ns));
            fit = fitExponentialT1(timing.waitTimes_ns, normalizedSignal);

            analysis.pulseCounts = pulseCounts;
            analysis.backgroundCount = backgroundCount;
            analysis.correctedPulseCounts = correctedPulseCounts;
            analysis.normalizedSignal = normalizedSignal;
            analysis.fit = fit;
            return;
        end

        error(['Reference pulse count is not larger than the dark-count background after the full acquisition. ' ...
            'First pulse window = %.0f counts, dark window = %.0f counts, corrected reference = %.0f counts. ' ...
            'This usually means the initialization pulse is missing or too weak, the detector trigger settings are wrong, ' ...
            'or the photons arrive outside the %.3f ns integration window.'], ...
            pulseCounts(1), backgroundCount, referenceCount, timing.integrationWindow_ns);
    end

    normalizedSignal = correctedPulseCounts(2:end) ./ referenceCount;
    fit = fitExponentialT1(timing.waitTimes_ns, normalizedSignal);

    analysis.pulseCounts = pulseCounts;
    analysis.backgroundCount = backgroundCount;
    analysis.correctedPulseCounts = correctedPulseCounts;
    analysis.normalizedSignal = normalizedSignal;
    analysis.fit = fit;
end

function counts = integrateWindow(histogram, startTime_ns, duration_ns, resolution_ps, finalBin)
    startBinZeroBased = round(startTime_ns * 1000 / resolution_ps);
    binCount = max(round(duration_ns * 1000 / resolution_ps), 1);
    indices = mod(startBinZeroBased + (0:binCount - 1), finalBin) + 1;
    counts = sum(histogram(indices));
end

function fit = fitExponentialT1(x_ns, y)
    x_ns = x_ns(:);
    y = y(:);
    valid = isfinite(x_ns) & isfinite(y);
    x_ns = x_ns(valid);
    y = y(valid);

    if numel(x_ns) < 2
        fit.parameters = [NaN, NaN, NaN];
        fit.curveX_ns = x_ns;
        fit.curveY = y;
        fit.T1_ns = NaN;
        return;
    end

    amp0 = max(y) - min(y);
    if amp0 <= 0
        amp0 = max(y);
    end

    tau0 = median(x_ns);
    offset0 = min(y);
    p0 = [amp0, tau0, offset0];

    objective = @(p) exponentialObjective(p, x_ns, y);
    options = optimset('Display', 'off');
    bestParameters = fminsearch(objective, p0, options);

    fit.parameters = bestParameters;
    fit.curveX_ns = linspace(min(x_ns), max(x_ns), 400);
    fit.curveY = exponentialModel(bestParameters, fit.curveX_ns);
    fit.T1_ns = bestParameters(2);
end

function err = exponentialObjective(p, x_ns, y)
    if p(1) < 0 || p(2) <= 0 || ~all(isfinite(p))
        err = 1e12;
        return;
    end

    yfit = exponentialModel(p, x_ns);
    if any(~isfinite(yfit))
        err = 1e12;
        return;
    end

    err = sum((y - yfit).^2);
end

function yfit = exponentialModel(p, x_ns)
    yfit = p(1) .* exp(-(x_ns ./ p(2))) + p(3);
end

function updatePlots(histogramPlot, dataPlot, fitPlot, timeAxis_ns, histogram, analysis, timing)
    set(histogramPlot, 'XData', timeAxis_ns(1:timing.histogramFinalBin), ...
        'YData', histogram(1:timing.histogramFinalBin));

    set(dataPlot, 'XData', timing.waitTimes_ns, 'YData', analysis.normalizedSignal);
    set(fitPlot, 'XData', analysis.fit.curveX_ns, 'YData', analysis.fit.curveY);

    figure(ancestor(histogramPlot, 'figure'));
    title(sprintf('Histogram, background = %.0f counts', analysis.backgroundCount));

    figure(ancestor(dataPlot, 'figure'));
    title(sprintf('T1 = %.3f ns', analysis.fit.T1_ns));
    drawnow;
end

function plotCreatedWaveforms(figHandle, initWaveform, triggerWaveform, timing, awg, cfg)
    figure(figHandle);
    clf(figHandle);

    totalSamples = max(numel(initWaveform), numel(triggerWaveform));
    timeAxis_ns = (0:totalSamples - 1) * awg.AWGStep;

    initWaveform = padWaveformForPlot(initWaveform, totalSamples);
    triggerWaveform = padWaveformForPlot(triggerWaveform, totalSamples);

    initAmplitude_Vpp = awg.MaxAmpForInitialization;
    initOffset_V = initAmplitude_Vpp / 2;
    initOutput_V = initOffset_V + 0.5 * initAmplitude_Vpp * initWaveform;

    triggerAmplitude_Vpp = cfg.awg.triggerHighVoltage_V - cfg.awg.triggerLowVoltage_V;
    triggerOffset_V = (cfg.awg.triggerHighVoltage_V + cfg.awg.triggerLowVoltage_V) / 2;
    triggerOutput_V = triggerOffset_V + 0.5 * triggerAmplitude_Vpp * triggerWaveform;

    ax1 = subplot(2, 1, 1, 'Parent', figHandle);
    stairs(ax1, timeAxis_ns, initOutput_V, 'b-', 'LineWidth', 1.2);
    hold(ax1, 'on');
    xline(ax1, timing.pulseStartTimes_ns(1), '--k', 'First init pulse');
    ylabel(ax1, 'Init (V)');
    title(ax1, 'Uploaded AWG waveforms');
    grid(ax1, 'on');
    xlim(ax1, [0, timing.sequenceDuration_ns]);

    ax2 = subplot(2, 1, 2, 'Parent', figHandle);
    stairs(ax2, timeAxis_ns, triggerOutput_V, 'r-', 'LineWidth', 1.2);
    hold(ax2, 'on');
    xline(ax2, timing.pulseStartTimes_ns(1), '--k', 'Trigger start');
    xlabel(ax2, 'Time (ns)');
    ylabel(ax2, 'Trigger (V)');
    grid(ax2, 'on');
    xlim(ax2, [0, timing.sequenceDuration_ns]);

    linkaxes([ax1, ax2], 'x');
    drawnow;
end

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

function saveMeasurementResults(results, figures, cfg)
    if isempty(cfg.output.baseFileName)
        baseName = ['T1_' char(datetime("now", "Format", "yyyyMMdd_HHmmss"))];
    else
        baseName = cfg.output.baseFileName;
    end

    if ~exist(cfg.output.outputFolder, 'dir')
        mkdir(cfg.output.outputFolder);
    end

    save(fullfile(cfg.output.outputFolder, [baseName '.mat']), 'results');
    saveas(figures.histogram, fullfile(cfg.output.outputFolder, [baseName '_histogram.png']));
    saveas(figures.t1, fullfile(cfg.output.outputFolder, [baseName '_T1.png']));
end

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
                supply.powerOff(cfg.supply.channel);
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
