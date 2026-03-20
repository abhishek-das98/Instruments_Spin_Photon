% MeasureT1.m
% Edit the settings in this block, then press Run.

biasVoltage_V = 0.00;
initializationPulseHeight = 1.00;  % User AWG level for the initialization pulse.
waitTimes_ns = 5:5:100;

darkCountDuration_ns = 5;
initializationPulseDuration_ns = 5;
finalWait_ns = [];  % Leave empty to use 2*max(waitTimes_ns).

acquisitionTime_s = 3;
binResolution_ps = 512;

triggerLowVoltage_V = -0.5;
triggerHighVoltage_V = 0.0;

saveResults = false;
outputFolder = pwd;
baseFileName = '';

cfg.waveform.darkCountDuration_ns = darkCountDuration_ns;
cfg.waveform.initDuration_ns = initializationPulseDuration_ns;
cfg.waveform.waitTimes_ns = waitTimes_ns;
cfg.waveform.finalWait_ns = finalWait_ns;

cfg.awg.channelInitialization = 1;
cfg.awg.channelTrigger = 2;
cfg.awg.userDelays_ns = [0, 0, 0, 0];
cfg.awg.initOnUserLevel = initializationPulseHeight;
cfg.awg.initOffUserLevel = 0.5;  % Internal AWG level that gives 0 V in your setup.
cfg.awg.triggerLowVoltage_V = triggerLowVoltage_V;
cfg.awg.triggerHighVoltage_V = triggerHighVoltage_V;
cfg.awg.settleTime_s = 0.5;

cfg.picoharp.acquisitionTime_s = acquisitionTime_s;
cfg.picoharp.resolution_ps = binResolution_ps;
cfg.picoharp.histogramOffset_ps = 0;
cfg.picoharp.syncOffset_ps = 0;
cfg.picoharp.syncDiscriminator_mV = 50;
cfg.picoharp.syncZeroCross_mV = 10;
cfg.picoharp.signalDiscriminator_mV = 50;
cfg.picoharp.signalZeroCross_mV = 10;
cfg.picoharp.countStop = 65535;
cfg.picoharp.pollPeriod_s = 0.25;

cfg.supply.biasVoltage_V = biasVoltage_V;
cfg.supply.currentLimit_A = 0.01;
cfg.supply.channel = 2;
cfg.supply.settleTime_s = 0.25;

cfg.analysis.integrationWindow_ns = initializationPulseDuration_ns;
cfg.analysis.backgroundWindowStart_ns = 0;
cfg.analysis.backgroundWindowDuration_ns = darkCountDuration_ns;
cfg.analysis.syncPeriodTolerance_ns = 2.0;

cfg.output.saveResults = saveResults;
cfg.output.outputFolder = outputFolder;
cfg.output.baseFileName = baseFileName;

cfg.cleanup.turnOutputsOff = true;
cfg.cleanup.disconnectInstruments = true;

results = runMeasureT1Internal(cfg);

function results = runMeasureT1Internal(cfg)
    cfg = validateConfig(cfg);
    addpath(fileparts(mfilename('fullpath')));

    awg = [];
    picoharp = [];
    supply = [];
    cleanupObj = onCleanup(@() cleanupInstruments(awg, picoharp, supply, cfg)); %#ok<NASGU>

    figures = createFigures();

    awg = ClassAWG.getInstance();
    picoharp = ClassPicoharp.getInstance();
    supply = ClassKeysightSupply.getInstance();

    connectAndConfigureInstruments(awg, picoharp, supply, cfg);
    timing = buildAndRunSequence(awg, cfg);

    pause(cfg.awg.settleTime_s);
    syncRate_Hz = double(picoharp.GetSyncRate());
    if syncRate_Hz <= 0
        error('PicoHarp sync rate is zero. Check the trigger cable and trigger waveform.');
    end

    timing.syncRate_Hz = syncRate_Hz;
    timing.syncPeriod_ns_fromPicoharp = 1e9 / syncRate_Hz;
    timing.histogramFinalBin = min(round(timing.sequenceDuration_ns * 1000 / picoharp.Resolution), 65536);

    if abs(timing.syncPeriod_ns_fromPicoharp - timing.sequenceDuration_ns) > cfg.analysis.syncPeriodTolerance_ns
        warning(['Measured PicoHarp sync period (%.3f ns) differs from the AWG sequence period ' ...
            '(%.3f ns). Using the AWG period for integration.'], ...
            timing.syncPeriod_ns_fromPicoharp, timing.sequenceDuration_ns);
    end

    results = acquireAndFit(picoharp, timing, cfg, figures);
    results.cfg = cfg;
    results.timing = timing;

    fprintf('\nExtracted T1 = %.3f ns\n', results.fit.T1_ns);

    if cfg.output.saveResults
        saveResults(results, figures, cfg);
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
end

function figures = createFigures()
    figures.histogram = figure('Name', 'T1 Histogram', 'Color', 'w');
    clf(figures.histogram);
    axes('Parent', figures.histogram);
    hold on;
    box on;
    xlabel('Time (ns)');
    ylabel('Counts');
    title('PicoHarp Histogram');

    figures.t1 = figure('Name', 'T1 Fit', 'Color', 'w');
    clf(figures.t1);
    axes('Parent', figures.t1);
    hold on;
    box on;
    xlabel('Wait time (ns)');
    ylabel('Normalized signal');
    title('T1 Extraction');
end

function connectAndConfigureInstruments(awg, picoharp, supply, cfg)
    try
        awg.CloseConnection();
    catch
    end

    try
        picoharp.CloseConnection();
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

    picoharp.connect();
    picoharp.SetTimeStop(cfg.picoharp.acquisitionTime_s);
    picoharp.SetResolution(cfg.picoharp.resolution_ps);
    picoharp.SetOffset(cfg.picoharp.histogramOffset_ps);
    picoharp.SetZeroOffset0(cfg.picoharp.syncOffset_ps);
    picoharp.SetZeroDiscr0(cfg.picoharp.syncDiscriminator_mV);
    picoharp.SetZeroCr0(cfg.picoharp.syncZeroCross_mV);
    picoharp.SetZeroDiscr1(cfg.picoharp.signalDiscriminator_mV);
    picoharp.SetZeroCr1(cfg.picoharp.signalZeroCross_mV);
    picoharp.SetCountStop(cfg.picoharp.countStop);

    supply.connect('TriplePowerSupply');
    supply.setCurrent(cfg.supply.currentLimit_A, cfg.supply.channel);
    supply.setVoltage(cfg.supply.biasVoltage_V, cfg.supply.channel);
    supply.powerOn(cfg.supply.channel);
    pause(cfg.supply.settleTime_s);
end

function timing = buildAndRunSequence(awg, cfg)
    [initEndTimes, initTypes, initParams, pulseStartTimes_ns, requestedSequenceDuration_ns] = buildInitializationSections(cfg);
    initWaveform = awg.CreateWaveform(initEndTimes, initTypes, initParams, cfg.awg.channelInitialization);

    [triggerEndTimes, triggerTypes, triggerParams] = buildTriggerSections( ...
        requestedSequenceDuration_ns, pulseStartTimes_ns(1));
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

function [endTimes, types, params] = buildTriggerSections(sequenceDuration_ns, firstPulseStart_ns)
    negativeStart_ns = firstPulseStart_ns;
    negativeEnd_ns = min(firstPulseStart_ns + sequenceDuration_ns / 2, sequenceDuration_ns);

    endTimes = [];
    types = {};
    params = {};

    if negativeStart_ns > 0
        endTimes(end + 1) = negativeStart_ns; %#ok<AGROW>
        types{end + 1} = 'dc'; %#ok<AGROW>
        params{end + 1}.Offset = 1; %#ok<AGROW>
    end

    endTimes(end + 1) = negativeEnd_ns; %#ok<AGROW>
    types{end + 1} = 'dc'; %#ok<AGROW>
    params{end + 1}.Offset = -1; %#ok<AGROW>

    if negativeEnd_ns < sequenceDuration_ns
        endTimes(end + 1) = sequenceDuration_ns; %#ok<AGROW>
        types{end + 1} = 'dc'; %#ok<AGROW>
        params{end + 1}.Offset = 1; %#ok<AGROW>
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

function results = acquireAndFit(picoharp, timing, cfg, figures)
    figure(figures.histogram);
    histogramPlot = plot(nan, nan, 'b-', 'LineWidth', 1.2);

    figure(figures.t1);
    dataPlot = plot(nan, nan, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Data');
    fitPlot = plot(nan, nan, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Fit');
    legend('Location', 'best');

    picoharp.StartAcquisition();

    while ~picoharp.CheckAquisitionDone()
        loopTimer = tic;
        [timeAxis_ns, histogram] = picoharp.GetHistogram();
        analysis = analyzeHistogram(histogram, timing, picoharp.Resolution);
        updatePlots(histogramPlot, dataPlot, fitPlot, timeAxis_ns, histogram, analysis, timing);
        pause(max(cfg.picoharp.pollPeriod_s - toc(loopTimer), 0));
    end

    [timeAxis_ns, histogram] = picoharp.GetHistogram();
    analysis = analyzeHistogram(histogram, timing, picoharp.Resolution);
    updatePlots(histogramPlot, dataPlot, fitPlot, timeAxis_ns, histogram, analysis, timing);
    picoharp.StopAcquisition();

    results.timeAxis_ns = timeAxis_ns;
    results.histogram = histogram;
    results.pulseCounts = analysis.pulseCounts;
    results.backgroundCounts = analysis.backgroundCount;
    results.normalizedSignal = analysis.normalizedSignal;
    results.correctedPulseCounts = analysis.correctedPulseCounts;
    results.fit = analysis.fit;
end

function analysis = analyzeHistogram(histogram, timing, resolution_ps)
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
        error('Reference pulse count is not larger than the dark-count background.');
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
    title(sprintf('PicoHarp Histogram, background = %.0f counts', analysis.backgroundCount));

    figure(ancestor(dataPlot, 'figure'));
    title(sprintf('T1 = %.3f ns', analysis.fit.T1_ns));
    drawnow;
end

function saveResults(results, figures, cfg)
    if isempty(cfg.output.baseFileName)
        baseName = ['T1_' datestr(now, 'yyyymmdd_HHMMss')];
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

function cleanupInstruments(awg, picoharp, supply, cfg)
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
            if ~isempty(picoharp)
                picoharp.StopAcquisition();
            end
        catch
        end

        try
            if ~isempty(picoharp)
                picoharp.CloseConnection();
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
