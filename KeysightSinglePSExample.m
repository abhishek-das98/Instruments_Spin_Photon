% -------------------------------------------------------------
% Example: Control Keysight Single-Output Power Supply
% -------------------------------------------------------------

% Get the singleton instance of the class
PS = ClassKeysightSupply.getInstance();

% Connect to the single-channel power supply
PS.connect('SinglePowerSupply');   % Opens VISA connection and queries *IDN?

% ---------------------------
% Configure Output
% ---------------------------

% Set output voltage to 5 V
PS.setVoltage(5);

% Set current limit to 0.5 A
PS.setCurrent(0.5);

% Enable output
PS.powerOn();

% Allow the supply and load to stabilize
pause(1.0);

% ---------------------------
% Turn output OFF and finalize
% ---------------------------

% Disable the output
PS.powerOff();

% Small delay before disconnecting
pause(0.5);

% Close the VISA session and clean up
PS.disconnect();
