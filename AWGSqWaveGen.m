% -------------------------------------------------------------------------
% Simple two-channel square-wave test for Keysight AWG (via ClassAWG)
%
% Channel 1:
%   - Logical levels requested: 0.6 V ("ON") and 0.1 V ("OFF")
%   - Due to the internal scaling in ClassAWG for the "Initialization"
%     channel, these are internally remapped and the AWG output levels
%     become approximately +0.2 V and -0.8 V.
%
% Channel 2:
%   - Logical levels requested: 0 V ("OFF") and 1 V ("ON")
%   - For this channel, the requested offsets map directly to 0 V and 1 V
%     at the waveform-data level (before the instrument's amplitude/offset
%     settings are applied).
%
% Timing:
%   - Channel 1: ~30 kHz square wave
%   - Channel 2: square wave with a period 3× longer than channel 1
%
% Note:
%   - All timing values are specified in nanoseconds (ns).
%   - Voltage scaling at the physical output also depends on the AWG
%     amplitude/offset settings configured inside ClassAWG.
% -------------------------------------------------------------------------

% Create (or retrieve) singleton instance of the AWG controller
AWG = ClassAWG.getInstance();

% Establish connection between the MATLAB object and the physical instrument
AWG.connect();
pause(1);   % Small delay to ensure the connection is fully established

% ---------------------- Channel 1: ~30 kHz -----------------------------

% End time stamps of each segment of the waveform (in ns)
Times_1 = [16.665e3, 33.33e3];     % Two segments forming one full period

% Waveform type for each segment
Types_1 = {'dc', 'dc'};            % Piecewise-constant DC segments

% Requested logical voltage levels for channel 1
% Internally, ClassAWG remaps these so that the actual output levels are
% approximately +0.2 V (for 0.6) and -0.8 V (for 0.1), due to the way the
% "Initialization" channel is implemented.
Params_1 = { ...
    struct('Offset', 0.6), ...     % "High" level
    struct('Offset', 0.1)  ...     % "Low" level
};

% Build the waveform vector for channel 1
SignalVec_1 = AWG.CreateWaveform(Times_1, Types_1, Params_1, 1);

% ---------------------- Channel 2: 1/3 frequency -----------------------

% Define six equal-duration segments over one full period of channel 2
Times_2 = (33.33e3 / 6) * (1:6);   % End times (ns) for 6 DC slices

% Waveform types: all DC segments
Types_2 = repmat({'dc'}, 1, numel(Times_2));

% Requested voltage levels for channel 2 (0 V / 1 V square wave)
Params_2 = { ...
    struct('Offset', 0), struct('Offset', 1), ...
    struct('Offset', 0), struct('Offset', 1), ...
    struct('Offset', 0), struct('Offset', 1) ...
};

% Build the waveform vector for channel 2
SignalVec_2 = AWG.CreateWaveform(Times_2, Types_2, Params_2, 2);

% ---------------------- Upload and run ----------------------------------

% Collect the per-channel waveforms into a segment cell array
Segment = cell(1, 2);
Segment{1} = SignalVec_1;   % Channel 1 waveform
Segment{2} = SignalVec_2;   % Channel 2 waveform

% Upload the segment to the AWG memory
AWG.UploadSegment(Segment);

% Select and run the uploaded segment
AWG.RunSegment(Segment);
