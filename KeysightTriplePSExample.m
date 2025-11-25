% -------------------------------------------------------------
% Example: Control Keysight Triple-Output Power Supply
% -------------------------------------------------------------

% Get the singleton instance of the class
PS = ClassKeysightSupply.getInstance();

% Connect to the triple-channel power supply
PS.connect('TriplePowerSupply');   % Opens VISA connection and queries *IDN?

% ---------------------------
% Configure Channel 1
% ---------------------------

% Set voltage on Channel 1 to 5 V
PS.setVoltage(5, 1);

% Set current limit on Channel 1 to 0.2 A
PS.setCurrent(0.2, 1);

% Enable output on Channel 1
PS.powerOn(1);

% Allow the supply to settle and the load to stabilize
pause(1.0);

% ---------------------------
% Turn output OFF and finalize
% ---------------------------

% Disable output on Channel 1
PS.powerOff(1);

% Small delay to ensure the command completes before disconnecting
pause(0.5);

% Disconnect the VISA session and clean up
PS.disconnect();
