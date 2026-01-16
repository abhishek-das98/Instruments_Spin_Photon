% -------------------------------------------------------------------------
% Simple two-channel sine-wave test for Keysight AWG (via ClassAWG)
%
% Channel 1:
%   - Sine wave with amplitude A1 and frequency f1
%
% Channel 2:
%   - Sine wave with amplitude A2 and frequency f2
%
% All timing values are in ns, consistent with ClassAWG.CreateWaveform.
% Frequency units are in GHz.
% 'lab' frame is used in this example. You can also use the 'rotating' frame
% -------------------------------------------------------------------------

% Get singleton instance and connect
AWG = ClassAWG.getInstance();
AWG.connect();
pause(1);

% ---------------------- Common timing ------------------------------------
% Total duration of the test waveform (here: 10 us)
T_total_ns = 10e3;   % 10 microseconds = 10,000 ns

% ---------------------- Channel 1: sine ----------------------------------
A1      = 0.5;        % amplitude
f1      = 1e-3;       % 1 MHz = 0.001 GHz
phi1    = 0;          % phase (radians)
frame1  = 'lab';      % frame index; adjust to your convention
offset1 = 0;          % DC offset in logical units

% One 'sine' segment that lasts the whole duration
Times_1 = T_total_ns;           % single end time stamp
Types_1 = {'sin'};
Params_1 = {struct( ...
    'Amplitude', A1, ...
    'Frequency', f1, ...
    'Phase',     phi1, ...
    'Frame',     frame1, ...
    'Offset',    offset1)};

% Build waveform vector for channel 1
SignalVec_1 = AWG.CreateWaveform(Times_1, Types_1, Params_1, 1);

% ---------------------- Channel 2: sine ----------------------------------
A2      = 1.0;        % amplitude
f2      = 0.5e-3;     % 500 kHz = 5e-4 GHz
phi2    = pi/2;       % phase shift relative to channel 1
frame2  = 'lab';      % frame index
offset2 = 0;          % DC offset

Times_2 = T_total_ns;           % same total duration
Types_2 = {'sine'};
Params_2 = {struct( ...
    'Amplitude', A2, ...
    'Frequency', f2, ...
    'Phase',     phi2, ...
    'Frame',     frame2, ...
    'Offset',    offset2)};

% Build waveform vector for channel 2
SignalVec_2 = AWG.CreateWaveform(Times_2, Types_2, Params_2, 2);

% ---------------------- Upload and run -----------------------------------

Segment = cell(1, 2);
Segment{1} = SignalVec_1;   % Channel 1 sine
Segment{2} = SignalVec_2;   % Channel 2 sine

AWG.UploadSegment(Segment);
AWG.RunSegment(Segment);
