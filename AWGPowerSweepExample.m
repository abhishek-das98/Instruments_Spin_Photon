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
numSweepSteps   = 20;                   % Number of steps from 0 -> max voltage
stepPause       = 0.25;                 % Pause (s) between voltage updates

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

% Turn on both outputs that will be swept
PS.powerOn(psChannel1);
PS.powerOn(psChannel2);

% Prepare sweep vectors
ch1Sweep = linspace(0, psMaxVoltageCh1, numSweepSteps + 1);
ch2Sweep = linspace(0, psMaxVoltageCh2, numSweepSteps + 1);

maxSteps = max(numel(ch1Sweep), numel(ch2Sweep));

fprintf('Starting voltage sweeps on power supply channels %d and %d...\n', ...
    psChannel1, psChannel2);

for idx = 1:maxSteps
    if idx <= numel(ch1Sweep)
        v1 = ch1Sweep(idx);
        PS.setVoltage(v1, psChannel1);
        fprintf('Requested Channel %d voltage: %.2f V\n', psChannel1, v1);
    end

    if idx <= numel(ch2Sweep)
        v2 = ch2Sweep(idx);
        PS.setVoltage(v2, psChannel2);
        fprintf('Requested Channel %d voltage: %.2f V\n', psChannel2, v2);
    end

    pause(stepPause);
end

fprintf('Voltage sweeps complete.\n');

% Optionally power off after the sweep
% PS.powerOff(psChannel1);
% PS.powerOff(psChannel2);
% PS.disconnect();
