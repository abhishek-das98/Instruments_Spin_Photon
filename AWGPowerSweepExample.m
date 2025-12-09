% -------------------------------------------------------------------------
% AWGPowerSweepExample.m
%
% Demonstrates how to:
%   1) Connect to the Keysight AWG and output a single-channel sine wave
%      on Channel 1 with a user-defined frequency.
%   2) Connect to the Keysight triple-output power supply and sweep Channel
%      1 from 0 -> 5 V and Channel 2 from 0 -> 12 V while reporting the
%      programmed values.
% -------------------------------------------------------------------------

%% ---------------------------- User inputs -------------------------------
% AWG configuration
awgChannel       = 1;          % Target AWG channel for the sine wave
sineAmplitude    = 0.5;        % Logical amplitude of the sine wave
sineFrequencyGHz = 1e-3;       % Frequency (in GHz). Example: 1e-3 = 1 MHz
sinePhase        = 0;          % Phase in radians
sineFrame        = 'lab';      % Frame label understood by ClassAWG
sineOffset       = 0;          % Logical DC offset
waveformDuration = 10e3;       % Duration in ns (e.g., 10e3 = 10 us)

% Power supply configuration
supplyName      = 'TriplePowerSupply'; % Options: 'SinglePowerSupply', 'TriplePowerSupply'
psChannel1      = 1;                    % Power-supply channel for first sweep
psChannel2      = 2;                    % Power-supply channel for second sweep
psMaxVoltageCh1 = 5;                    % Target voltage for Channel 1 (V)
psMaxVoltageCh2 = 12;                   % Target voltage for Channel 2 (V)
psStepCh1       = 0.25;                 % Voltage step for Channel 1 (V)
psStepCh2       = 0.50;                 % Voltage step for Channel 2 (V)
stepPause       = 0.25;                 % Pause (s) between voltage updates

% Power meter configuration
pmDwellSeconds      = 5;   % Total time to dwell at each sweep point
pmSampleIntervalSec = 1;   % Interval between power samples (seconds)

%% ---------------------------- AWG set up --------------------------------
AWG = ClassAWG.getInstance();
AWG.connect();
pause(1); % allow the connection to stabilize

% Build a single sine segment for the requested channel
Times_1  = waveformDuration;  % Single end timestamp in ns
Types_1  = {'sin'};
Params_1 = {struct( ...
    'Amplitude', sineAmplitude, ...
    'Frequency', sineFrequencyGHz, ...
    'Phase',     sinePhase, ...
    'Frame',     sineFrame, ...
    'Offset',    sineOffset)};

SignalVec_1 = AWG.CreateWaveform(Times_1, Types_1, Params_1, awgChannel);

% Upload and run only Channel 1
Segment = cell(1, 2);
Segment{awgChannel} = SignalVec_1;

AWG.UploadSegment(Segment);
AWG.RunSegment(Segment);

%% ----------------------- Power supply set up ----------------------------
PS = ClassKeysightSupply.getInstance();
PS.connect(supplyName);

% Connect to the power meter
PM = ClassThorlabsPM100D.getInstance();
PM.connect();

% Turn on both outputs that will be swept
PS.powerOn(psChannel1);
PS.powerOn(psChannel2);

% Prepare sweep vectors
ch1Sweep = unique([0:psStepCh1:psMaxVoltageCh1, psMaxVoltageCh1]);
ch2Sweep = unique([0:psStepCh2:psMaxVoltageCh2, psMaxVoltageCh2]);

maxSteps = max(numel(ch1Sweep), numel(ch2Sweep));

numAvgSamples = max(1, floor(pmDwellSeconds / pmSampleIntervalSec));
avgPowerLog   = nan(1, maxSteps);
voltageLogCh1 = nan(1, maxSteps);
voltageLogCh2 = nan(1, maxSteps);

fprintf('Starting voltage sweeps on power supply channels %d and %d...\n', ...
    psChannel1, psChannel2);

for idx = 1:maxSteps
    if idx <= numel(ch1Sweep)
        v1 = ch1Sweep(idx);
    else
        v1 = ch1Sweep(end);
    end
    PS.setVoltage(v1, psChannel1);
    fprintf('Requested Channel %d voltage: %.2f V\n', psChannel1, v1);
    voltageLogCh1(idx) = v1;

    if idx <= numel(ch2Sweep)
        v2 = ch2Sweep(idx);
    else
        v2 = ch2Sweep(end);
    end
    PS.setVoltage(v2, psChannel2);
    fprintf('Requested Channel %d voltage: %.2f V\n', psChannel2, v2);
    voltageLogCh2(idx) = v2;

    % Allow supply to settle before measuring power
    pause(stepPause);

    powerSamples = zeros(1, numAvgSamples);
    for sampleIdx = 1:numAvgSamples
        pause(pmSampleIntervalSec);
        powerSamples(sampleIdx) = PM.GetPower();
        fprintf('  Power sample %d/%d: %.6f W\n', sampleIdx, numAvgSamples, powerSamples(sampleIdx));
    end

    avgPower = mean(powerSamples);
    avgPowerLog(idx) = avgPower;
    fprintf('  Average power at V1=%.2f V, V2=%.2f V: %.6f W\n', v1, v2, avgPower);
end

fprintf('Voltage sweeps complete.\n');

% Report the minimum measured power and corresponding voltages
[minPower, minIdx] = min(avgPowerLog);
fprintf(['Minimum average power: %.6f W at step %d ', ...
         '(Channel %d: %.2f V, Channel %d: %.2f V)\n'], ...
        minPower, minIdx, psChannel1, voltageLogCh1(minIdx), psChannel2, voltageLogCh2(minIdx));

% Plot power vs. sweep step for a quick visual overview
figure;
plot(1:maxSteps, avgPowerLog, '-o');
xlabel('Sweep step');
ylabel('Average power (W)');
title('Power vs. sweep step');
grid on;
hold on;
plot(minIdx, minPower, 'r*', 'MarkerSize', 10);
legend('Average power', 'Minimum');

% Optionally power off after the sweep
% PS.powerOff(psChannel1);
% PS.powerOff(psChannel2);
% PS.disconnect();
