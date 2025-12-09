% -------------------------------------------------------------------------
% FindingMaxOutPowerSweepVoltage.m
%
% Demonstrates how to:
%   1) Applies different bias boltages to the amplifier (0 -> 12 V)
%   2) Applies different amplifaciton voltages to the amplifier (0 -> 5 V)
%   3) Amplify the AWG signal
%   4) See the effect of different sinnusoidal signals levels on the output power
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
pmWavelengthNm      = 930; % Wavelength (nm) to configure on the power meter

%% ---------------------------- AWG set up --------------------------------
AWG = ClassAWG.getInstance();
AWG.connect(1); % only connects to channel 1
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
pause(1); % allow the connection to stabilize

% Connect to the power meter
PM = ClassThorlabsPM100D.getInstance();
PM.connect();
pause(1); % allow the connection to stabilize
PM.SetWavelength(pmWavelengthNm);


% Turn on both outputs that will be swept
PS.powerOn(psChannel1);
PS.powerOn(psChannel2);

% Prepare sweep vectors
ch1Sweep = unique([0:psStepCh1:psMaxVoltageCh1, psMaxVoltageCh1]);
ch2Sweep = unique([0:psStepCh2:psMaxVoltageCh2, psMaxVoltageCh2]);

numAvgSamples = max(1, floor(pmDwellSeconds / pmSampleIntervalSec));
avgPowerGrid  = nan(numel(ch2Sweep), numel(ch1Sweep));
voltageLogCh1 = nan(numel(ch2Sweep), numel(ch1Sweep));
voltageLogCh2 = nan(numel(ch2Sweep), numel(ch1Sweep));

totalSteps = numel(ch2Sweep) * numel(ch1Sweep);

fprintf(['Starting nested sweeps: Channel %d (amplifying voltage) inside ', ...
    'each Channel %d bias voltage level...\n'], psChannel1, psChannel2);

stepCounter = 0;
for biasIdx = 1:numel(ch2Sweep)
    v2 = ch2Sweep(biasIdx);
    PS.setVoltage(v2, psChannel2);
    fprintf('Set Channel %d bias to %.2f V\n', psChannel2, v2);

    for ampIdx = 1:numel(ch1Sweep)
        v1 = ch1Sweep(ampIdx);
        PS.setVoltage(v1, psChannel1);
        fprintf('  Set Channel %d amplifying voltage to %.2f V\n', psChannel1, v1);

        stepCounter = stepCounter + 1;
        fprintf('  Sweep step %d/%d (bias index %d, amp index %d)\n', ...
            stepCounter, totalSteps, biasIdx, ampIdx);

        voltageLogCh1(biasIdx, ampIdx) = v1;
        voltageLogCh2(biasIdx, ampIdx) = v2;

        % Allow supply to settle before measuring power
        pause(stepPause);

        powerSamples = zeros(1, numAvgSamples);
        for sampleIdx = 1:numAvgSamples
            pause(pmSampleIntervalSec);
            powerSamples(sampleIdx) = PM.GetPower();
            fprintf('    Power sample %d/%d: %.6f W\n', sampleIdx, numAvgSamples, powerSamples(sampleIdx));
        end

        avgPower = mean(powerSamples);
        avgPowerGrid(biasIdx, ampIdx) = avgPower;
        fprintf('    Average power at Vbias=%.2f V, Vamp=%.2f V: %.6f W\n', ...
            v2, v1, avgPower);
    end
end

fprintf('Voltage sweeps complete.\n');

% Report the maximum measured power and corresponding voltages
[maxPower, maxLinearIdx] = max(avgPowerGrid(:));
[maxBiasIdx, maxAmpIdx]  = ind2sub(size(avgPowerGrid), maxLinearIdx);
fprintf(['Maximum average power: %.6f W at bias %.2f V (Channel %d), ', ...
         'amplifying %.2f V (Channel %d)\n'], ...
        maxPower, voltageLogCh2(maxBiasIdx, maxAmpIdx), psChannel2, ...
        voltageLogCh1(maxBiasIdx, maxAmpIdx), psChannel1);

% Plot a heatmap of power vs. amplifying and bias voltages
figure;
imagesc(ch1Sweep, ch2Sweep, avgPowerGrid);
set(gca, 'YDir', 'normal');
xlabel(sprintf('Channel %d amplifying voltage (V)', psChannel1));
ylabel(sprintf('Channel %d bias voltage (V)', psChannel2));
title('Average power across nested voltage sweeps');
colorbar;
hold on;
maxMarker = plot(voltageLogCh1(maxBiasIdx, maxAmpIdx), ...
    voltageLogCh2(maxBiasIdx, maxAmpIdx), 'r*', 'MarkerSize', 10, 'LineWidth', 1.5);
legend(maxMarker, 'Maximum power');

% Stop AWG output and close connection
AWG.stopAWG(awgChannel);
AWG.CloseConnection();

% Power off supply channels and disconnect
PS.powerOff(psChannel1);
PS.powerOff(psChannel2);
PS.disconnect();

fprintf('Experiment completed and instruments shut down.\n');
