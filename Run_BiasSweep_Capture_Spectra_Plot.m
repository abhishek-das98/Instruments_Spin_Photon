% Run_BiasSweep_And_Plot2D
% NOTE: This script is configured for the Keysight single-channel supply only.
% Runs forward + reverse bias sweep, saves CSV, then plots 2D intensity map.
% For plotting cleanup: if intensity > threshold, replace with previous-voltage
% value at the same wavelength (instead of deleting the row).

clc;
clear;
close all;

%% ---------------- User settings ----------------
experimentName           = 'Experiment_Spectrometer_Mode';
visibleLightField        = true;

targetCenterNm           = 930;
targetGratingGmm         = 300;     % manual selection prompt
excitationWavelengthNm   = 780;     % for plot title
exposureMs               = 1000;
settleTimeSeconds        = 0.3;
manualGratingWaitSeconds = 120;
intensityThresholdCounts = 800;     % plotting cleanup threshold

voltageSweepForward      = 0.0:0.1:3.5;
voltageSweepReverse      = 0.0:0.1:3.5;

excitationPower_uW       = 57.18;
xPosition                = 1299;
zPosition                = 3718;

timestampTag = datestr(now, 'yyyymmdd_HHMMSS');
powerTag = formatValueForFileName(excitationPower_uW);
xTag = formatValueForFileName(xPosition);
zTag = formatValueForFileName(zPosition);
csvFile = sprintf('DBR_QD_BiasSweep_780nm_x_%s_z_%s_P_%suW_%s.csv', ...
    xTag, zTag, powerTag, timestampTag);

%% ---------------- CSV header ----------------
fid = fopen(csvFile, 'w');
if fid < 0
    error('Failed to create CSV file: %s', csvFile);
end
fprintf(fid, '%s\n', ...
    'timestamp,direction,step_index,set_voltage_V,measured_voltage_V,measured_current_A,center_wavelength_nm,grating_g_per_mm,exposure_ms,wavelength_nm,intensity_counts');
fclose(fid);

%% ---------------- Hardware objects ----------------
lf = [];
ps = [];
isConnected = false;
isOutputOn = false;
err = [];

try
    % LightField setup
    lf = ClassLightFieldWrapper(visibleLightField, experimentName);
    lf.setFrames(1);
    lf.setExposureMs(exposureMs);
    lf.setCenterWavelengthNm(targetCenterNm);
    fprintf('LightField primary setup complete: center = %.1f nm, exposure = %.0f ms\n', ...
        targetCenterNm, exposureMs);
    fprintf('Please manually change the grating to %d g/mm now.\n', targetGratingGmm);
    fprintf('Waiting %d seconds before continuing...\n', manualGratingWaitSeconds);
    pause(manualGratingWaitSeconds);
    input(sprintf('Confirm grating is set to %d g/mm, then press Enter to continue...', targetGratingGmm), 's');

    % Keysight setup
    ps = ClassKeysightSupply.getInstance();
    ps.connect('SinglePowerSupply');
    isConnected = true;

    ps.setVoltage(0.0);
    ps.powerOn();
    isOutputOn = true;

    % Forward sweep
    runSweepAndAppendCsv(lf, ps, voltageSweepForward, ...
        'FORWARD', targetCenterNm, targetGratingGmm, exposureMs, settleTimeSeconds, csvFile);

    % Pause for manual reverse-bias wiring
    fprintf('\nReached %.2f V (forward sweep complete).\n', voltageSweepForward(end));
    ps.setVoltage(0.0);
    ps.powerOff();
    isOutputOn = false;

    input('Reverse the supply polarity now, then press Enter to continue reverse-bias sweep...', 's');

    ps.powerOn();
    isOutputOn = true;

    % Reverse-bias sweep
    runSweepAndAppendCsv(lf, ps, voltageSweepReverse, ...
        'REVERSE', targetCenterNm, targetGratingGmm, exposureMs, settleTimeSeconds, csvFile);

catch ME
    err = ME;
end

%% ---------------- Cleanup (always) ----------------
try
    if isOutputOn && ~isempty(ps)
        ps.setVoltage(0.0);
        ps.powerOff();
    end
catch MEc
    fprintf(2, 'Cleanup warning (power off): %s\n', MEc.message);
end

try
    if isConnected && ~isempty(ps)
        ps.disconnect();
    end
catch MEc
    fprintf(2, 'Cleanup warning (disconnect): %s\n', MEc.message);
end

try
    if ~isempty(lf)
        lf.close();
    end
catch MEc
    fprintf(2, 'Cleanup warning (LightField close): %s\n', MEc.message);
end

if ~isempty(err)
    rethrow(err);
end

fprintf('\nSweep complete. Data saved to:\n%s\n', csvFile);

%% ---------------- Plot after experiment ----------------
[figPath, pngPath] = plot2DFromBiasSweepCsv(csvFile, excitationWavelengthNm, intensityThresholdCounts);
fprintf('Saved 2D map to:\n%s\n%s\n', figPath, pngPath);

%% ---------------- Local helper functions ----------------
function runSweepAndAppendCsv(lf, ps, voltageList, ...
    directionLabel, centerNm, gratingGmm, exposureMs, settleTimeSeconds, csvFile)

for idx = 1:numel(voltageList)
    vSet = voltageList(idx);

    ps.setVoltage(vSet);
    pause(settleTimeSeconds);

    vRead = ps.readVoltage();
    iRead = ps.readCurrent();

    [spectrumCounts, wlNm] = lf.acquireSpectrum1D('sumY');
    if isempty(wlNm)
        error('No wavelength calibration found in LightField.');
    end

    ts = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    appendSpectrumRows(csvFile, ts, directionLabel, idx, vSet, vRead, iRead, ...
        centerNm, gratingGmm, exposureMs, wlNm, spectrumCounts);

    fprintf('[%s] Step %d/%d | Vset=%.2f V | Vread=%.4f V | Iread=%.6f A | points=%d\n', ...
        directionLabel, idx, numel(voltageList), vSet, vRead, iRead, numel(wlNm));
end
end

function appendSpectrumRows(csvFile, timestampStr, directionLabel, stepIndex, ...
    vSet, vRead, iRead, centerNm, gratingGmm, exposureMs, wlNm, counts)

wlNm = wlNm(:);
counts = counts(:);
if numel(wlNm) ~= numel(counts)
    error('Wavelength and intensity lengths do not match.');
end

fid = fopen(csvFile, 'a');
if fid < 0
    error('Failed to open CSV for append: %s', csvFile);
end
cleanObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

for k = 1:numel(wlNm)
    fprintf(fid, '%s,%s,%d,%.4f,%.6f,%.9f,%.2f,%d,%.0f,%.9f,%.9f\n', ...
        timestampStr, directionLabel, stepIndex, vSet, vRead, iRead, ...
        centerNm, gratingGmm, exposureMs, wlNm(k), counts(k));
end
end

function [figPath, pngPath] = plot2DFromBiasSweepCsv(csvFile, excitationWavelengthNm, thresholdCounts)
T = readtable(csvFile, 'TextType', 'string');

requiredCols = ["direction","set_voltage_V","wavelength_nm","intensity_counts", ...
                "grating_g_per_mm","exposure_ms"];
missing = requiredCols(~ismember(requiredCols, string(T.Properties.VariableNames)));
if ~isempty(missing)
    error('Missing required columns: %s', strjoin(cellstr(missing), ', '));
end

direction = upper(strtrim(T.direction));
signedVoltage = T.set_voltage_V;
isReverse = (direction == "REVERSE");
signedVoltage(isReverse) = -abs(signedVoltage(isReverse));
signedVoltage(~isReverse) = abs(signedVoltage(~isReverse));

vRound = round(signedVoltage, 6);
wRound = round(T.wavelength_nm, 6);
vAxis = unique(vRound, 'sorted'); % negative -> positive
wAxis = unique(wRound, 'sorted');

[~, vIdx] = ismember(vRound, vAxis);
[~, wIdx] = ismember(wRound, wAxis);
Zraw = accumarray([vIdx, wIdx], T.intensity_counts, ...
                  [numel(vAxis), numel(wAxis)], @mean, NaN);

% Replace high outliers with previous-voltage values at same wavelength.
Z = Zraw;
nReplaced = 0;
for c = 1:size(Z, 2)
    for r = 2:size(Z, 1)
        if ~isnan(Z(r, c)) && Z(r, c) > thresholdCounts && ~isnan(Z(r-1, c))
            Z(r, c) = Z(r-1, c);
            nReplaced = nReplaced + 1;
        end
    end
end
fprintf('Threshold replacement complete: %d points replaced (threshold = %g).\n', ...
    nReplaced, thresholdCounts);

[~, baseName, ~] = fileparts(csvFile);
powerToken = regexp(baseName, 'P_([^_]+)uW', 'tokens', 'once');
if isempty(powerToken)
    powerStr = 'unknown';
else
    powerStr = strrep(powerToken{1}, 'p', '.');
    powerStr = strrep(powerStr, 'm', '-');
end

dateToken = regexp(baseName, '(\d{8}_\d{6})$', 'tokens', 'once');
if isempty(dateToken)
    dateStr = datestr(now, 'yyyy-mm-dd HH:MM:SS');
else
    dt = datetime(dateToken{1}, 'InputFormat', 'yyyyMMdd_HHmmss');
    dateStr = datestr(dt, 'yyyy-mm-dd HH:MM:SS');
end

gratingGmm = mode(T.grating_g_per_mm);
exposureMs = mode(T.exposure_ms);

fig = figure('Color', 'w');
imagesc(wAxis, vAxis, Z);
set(gca, 'YDir', 'normal');
colormap(turbo);
cb = colorbar;
ylabel(cb, 'Intensity (counts)');

xlabel('Wavelength (nm)');
ylabel('Supply Voltage (V)');
title(sprintf(['2D Bias Sweep Map | Power = %s uW | Excitation = %d nm | ' ...
               'Grating = %d g/mm | Exposure = %d ms | Date = %s'], ...
               powerStr, excitationWavelengthNm, round(gratingGmm), round(exposureMs), dateStr), ...
      'Interpreter', 'none');
ylim([min(vAxis), max(vAxis)]);

outBase = sprintf('%s_2D_IntensityMap', baseName);
figPath = [outBase '.fig'];
pngPath = [outBase '.png'];
savefig(fig, figPath);
exportgraphics(fig, pngPath, 'Resolution', 300);
end

function out = formatValueForFileName(val)
if isnumeric(val)
    out = num2str(val, '%.8g');
else
    out = char(string(val));
end
out = strrep(out, '.', 'p');
out = strrep(out, '-', 'm');
out = regexprep(out, '[^a-zA-Z0-9_]', '');
end
