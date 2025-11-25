classdef (Sealed) ClassKeysightSupply < handle
    %CLASSKEYSIGHTSUPPLY Singleton wrapper for Keysight DC power supplies
    %
    %   Usage (example):
    %       ps = ClassKeysightSupply.getInstance();
    %       ps.connect('TriplePowerSupply');
    %       ps.setVoltage(5.0, 1);
    %       ps.setCurrent(0.2, 1);
    %       ps.powerOn(1);
    %
    %   Remember to call:
    %       ps.disconnect();
    %   when you are done.

    properties (Dependent = true)
        MaxVoltage_SinglePowerSupply
        MaxVoltage_TriplePowerSupply
        VoltageResolution
    end

    properties (Access = private)
        PossibleNames = {'SinglePowerSupply', 'TriplePowerSupply'};

        % VISA resource strings for the instruments
        viRscNameSingle = 'USB0::10893::5634::MY61002609::0::INSTR'; % Single-output supply
        viRscNameTriple = 'USB0::10893::4354::MY61007414::0::INSTR'; % Triple-output supply

        InstrObj            % VISA object handle
        CurrentSupplyName   % 'SinglePowerSupply' or 'TriplePowerSupply'

        % Internal storage for dependent properties
        MaxVoltage_SinglePowerSupply_Private = 60;  % <-- set to your actual instrument limit
        MaxVoltage_TriplePowerSupply_Private = 30;  % <-- set to your actual instrument limit

        VoltageResolutionPrivate = 0.01; % V resolution
        UploadTimeOut = 20;              % s, VISA timeout
    end

    methods (Access = private)
        function obj = ClassKeysightSupply()
            % Private constructor for singleton pattern
        end
    end

    methods (Static)
        function obj = getInstance()
            %GETINSTANCE Return the singleton instance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassKeysightSupply;
            end
            obj = localObj;
        end
    end

    %% Connection methods
    methods
        % Connect to the power supply
        function connect(obj, SupplyName)
            %CONNECT Open a VISA connection to the selected Keysight supply
            %
            %   SupplyName must be one of:
            %       'SinglePowerSupply' or 'TriplePowerSupply'.

            obj.CurrentSupplyName = SupplyName;
            viRscName = obj.selectResource(SupplyName);

            % Check if InstrObj is already connected to prevent reconnection
            if isempty(obj.InstrObj) || ~isvalid(obj.InstrObj)
                % Create a VISA object with the appropriate vendor and resource
                obj.InstrObj = visa('keysight', viRscName);
                obj.InstrObj.Timeout = obj.UploadTimeOut;
            else
                error('Instrument already connected. Resource: %s. Disconnect before reconnecting.', viRscName);
            end

            % Try to open the connection
            try
                fopen(obj.InstrObj);  % Open the VISA connection

                % Verify the connection by querying the instrument ID
                fprintf(obj.InstrObj, '*IDN?');  % Send ID query
                idn = fscanf(obj.InstrObj);      % Read the response
                fprintf('Connected to: %s\n', strtrim(idn));  % Display the instrument ID

            catch ME
                error('Failed to connect to the instrument: %s', ME.message);
            end
        end

        function disconnect(obj)
            %DISCONNECT Close the VISA connection to the instrument
            try
                if ~isempty(obj.InstrObj) && strcmp(obj.InstrObj.Status, 'open')
                    fclose(obj.InstrObj);
                    delete(obj.InstrObj);
                    obj.InstrObj = [];
                    fprintf('Connection closed.\n');
                else
                    fprintf('No active connection found to close.\n');
                end
            catch ME
                error('Failed to disconnect from the instrument: %s', ME.message);
            end
        end
    end

    %% Dependent property getters
    methods
        function MaxVoltage_SinglePowerSupply = get.MaxVoltage_SinglePowerSupply(obj)
            MaxVoltage_SinglePowerSupply = obj.MaxVoltage_SinglePowerSupply_Private;
        end

        function MaxVoltage_TriplePowerSupply = get.MaxVoltage_TriplePowerSupply(obj)
            MaxVoltage_TriplePowerSupply = obj.MaxVoltage_TriplePowerSupply_Private;
        end

        function VoltageResolution = get.VoltageResolution(obj)
            VoltageResolution = obj.VoltageResolutionPrivate;
        end
    end

    %% SCPI high-level methods: Set & Read
    methods
        function setVoltage(obj, voltage, channel)
            %SETVOLTAGE Set output voltage.
            %
            %   For SinglePowerSupply:
            %       setVoltage(obj, voltage)
            %
            %   For TriplePowerSupply:
            %       setVoltage(obj, voltage, channel)  % channel = 1, 2, or 3

            if nargin < 3
                channel = []; % Not needed for single-output supply
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Optional: simple safety check against max voltage
                switch obj.CurrentSupplyName
                    case 'SinglePowerSupply'
                        vmax = obj.MaxVoltage_SinglePowerSupply_Private;
                    case 'TriplePowerSupply'
                        vmax = obj.MaxVoltage_TriplePowerSupply_Private;
                    otherwise
                        vmax = Inf;
                end
                if ~isempty(vmax) && isfinite(vmax) && voltage > vmax
                    error('Requested voltage (%.2f V) exceeds max limit (%.2f V).', voltage, vmax);
                end

                cmd = obj.constructCommand('VOLT', voltage, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage set to %.2f V on Channel %d\n', obj.CurrentSupplyName, voltage, channel);
                else
                    fprintf('[%s] Voltage set to %.2f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to set the voltage: %s', ME.message);
            end
        end

        function setCurrent(obj, current, channel)
            %SETCURRENT Set output current limit.
            %
            %   For SinglePowerSupply:
            %       setCurrent(obj, current)
            %
            %   For TriplePowerSupply:
            %       setCurrent(obj, current, channel)  % channel = 1, 2, or 3

            if nargin < 3
                channel = [];
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                cmd = obj.constructCommand('CURR', current, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current set to %.3f A on Channel %d\n', obj.CurrentSupplyName, current, channel);
                else
                    fprintf('[%s] Current set to %.3f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to set the current: %s', ME.message);
            end
        end

        function voltage = readVoltage(obj, channel)
            %READVOLTAGE Measure output voltage.
            %
            %   v = readVoltage(obj)           % single-output
            %   v = readVoltage(obj, channel)  % triple-output

            if nargin < 2
                channel = [];
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                cmd = obj.constructCommand('MEAS:VOLT?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                voltageStr = fscanf(obj.InstrObj);
                voltage = str2double(voltageStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage on Channel %d: %.3f V\n', obj.CurrentSupplyName, channel, voltage);
                else
                    fprintf('[%s] Voltage: %.3f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to read the voltage: %s', ME.message);
            end
        end

        function current = readCurrent(obj, channel)
            %READCURRENT Measure output current.
            %
            %   i = readCurrent(obj)           % single-output
            %   i = readCurrent(obj, channel)  % triple-output

            if nargin < 2
                channel = [];
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                cmd = obj.constructCommand('MEAS:CURR?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                currentStr = fscanf(obj.InstrObj);
                current = str2double(currentStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current on Channel %d: %.6f A\n', obj.CurrentSupplyName, channel, current);
                else
                    fprintf('[%s] Current: %.6f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to read the current: %s', ME.message);
            end
        end
    end

    %% Power ON/OFF
    methods
        function powerOn(obj, channel)
            %POWERON Enable output(s).
            %
            %   powerOn(obj)           % single-output
            %   powerOn(obj, channel)  % triple-output

            if nargin < 2
                channel = [];
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                cmd = obj.constructCommand('OUTP ON', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned ON for Channel %d\n', obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned ON\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power on: %s', ME.message);
            end
        end

        function powerOff(obj, channel)
            %POWEROFF Disable output(s).
            %
            %   powerOff(obj)           % single-output
            %   powerOff(obj, channel)  % triple-output

            if nargin < 2
                channel = [];
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                cmd = obj.constructCommand('OUTP OFF', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned OFF for Channel %d\n', obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned OFF\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power off: %s', ME.message);
            end
        end
    end

    %% Low-level SCPI construction + resource selection
    methods
        function cmd = constructCommand(obj, baseCmd, value, channel, commandType)
            %CONSTRUCTCOMMAND Build SCPI command string.

            if nargin < 5
                error('Command type must be specified as "read", "power", or "set".');
            end

            % Validate channel number for TriplePowerSupply
            if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                if isempty(channel) || ~ismember(channel, [1, 2, 3])
                    error('Invalid channel number. Valid channels are 1, 2, or 3.');
                end
            end

            switch commandType
                case 'read'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = baseCmd;  % Example: "MEAS:VOLT?"
                    else
                        cmd = sprintf('%s (@%d)', baseCmd, channel);  % "MEAS:VOLT? (@2)"
                    end

                case 'set'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = sprintf('%s %.3f', baseCmd, value);  % "VOLT 5.000"
                    else
                        cmd = sprintf('%s %.3f, (@%d)', baseCmd, value, channel);  % "VOLT 12.000, (@2)"
                    end

                case 'power'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = sprintf('%s', baseCmd);  % "OUTP ON"
                    else
                        cmd = sprintf('%s, (@%d)', baseCmd, channel);  % "OUTP ON, (@2)"
                    end

                otherwise
                    error('Invalid command type. Use "read", "power", or "set".');
            end
        end

        function rscName = selectResource(obj, SupplyName)
            %SELECTRESOURCE Return VISA resource string for given supply name.

            validNames = obj.PossibleNames;

            if ~ismember(SupplyName, validNames)
                errorMessage = sprintf('Invalid power supply name. Valid names are: %s', ...
                    strjoin(validNames, ', '));
                error(errorMessage);
            end

            switch SupplyName
                case 'SinglePowerSupply'
                    rscName = obj.viRscNameSingle;
                case 'TriplePowerSupply'
                    rscName = obj.viRscNameTriple;
                otherwise
                    error('Unknown power supply name.');
            end
        end
    end
end
