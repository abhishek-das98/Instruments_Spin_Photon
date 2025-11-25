classdef (Sealed) ClassKeysightSupply < handle
    % ClassKeysightSupply
    %   Singleton wrapper to control Keysight single- and triple-output
    %   power supplies using VISA / SCPI commands.

    properties (Dependent = true)
        MaxVoltage_SinglePowerSupply
        MaxVoltage_TriplePowerSupply
        VoltageResolution
    end

    properties (Access = private)
        PossibleNames = {'SinglePowerSupply', 'TriplePowerSupply'}

        % Power Supply USB Addresses (readable from the instrument)
        viRscNameSingle = 'USB0::10893::5634::MY61002609::0::INSTR'; % Single-output supply
        viRscNameTriple = 'USB0::10893::4354::MY61007414::0::INSTR'; % Triple-output supply

        InstrObj            % VISA object
        CurrentSupplyName   % 'SinglePowerSupply' or 'TriplePowerSupply'

        MaxVoltage_SinglePowerSupply_Private
        MaxVoltage_TriplePowerSupply_Private

        VoltageResolutionPrivate = 0.01;
        UploadTimeOut = 20; % Timeout (s) for VISA operations
    end

    methods (Access = private)
        function obj = ClassKeysightSupply()
            % Private constructor for singleton pattern.
            % If desired, initialize hardware-specific limits here, e.g.:
            % obj.MaxVoltage_SinglePowerSupply_Private  = 30;
            % obj.MaxVoltage_TriplePowerSupply_Private = 30;
        end
    end

    methods (Static)
        function obj = getInstance()
            %GETINSTANCE Return the singleton instance of ClassKeysightSupply.
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassKeysightSupply;
            end
            obj = localObj;
        end
    end

    methods
        % -----------------------------
        % Connection handling
        % -----------------------------

        function connect(obj, SupplyName)
            % CONNECT Open a VISA connection to the selected Keysight supply.
            %
            %   obj.connect('SinglePowerSupply')
            %   obj.connect('TriplePowerSupply')

            obj.CurrentSupplyName = SupplyName;
            viRscName = obj.selectResource(SupplyName);

            % Create or reuse VISA object
            if isempty(obj.InstrObj) || ~isvalid(obj.InstrObj)
                % Create a VISA object with the appropriate vendor and resource
                obj.InstrObj = visa('keysight', viRscName);
                obj.InstrObj.Timeout = obj.UploadTimeOut;
            else
                % If object exists and is already open, prevent reconnect
                if strcmp(obj.InstrObj.Status, 'open')
                    error('Instrument already connected. Disconnect before calling connect again.');
                end
                % If it exists but is closed, we will reopen it below.
            end

            % Try to open the connection
            try
                fopen(obj.InstrObj);  % Open (or reopen) the VISA connection

                % Verify the connection by querying the instrument ID
                fprintf(obj.InstrObj, '*IDN?');  % Send ID query
                idn = fscanf(obj.InstrObj);      % Read the response
                fprintf('Connected to: %s\n', strtrim(idn));  % Display the instrument ID

            catch ME
                error('Failed to connect to the instrument: %s', ME.message);
            end
        end

        function disconnect(obj)
            % DISCONNECT Close the VISA connection and clean up.

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

    methods
        % -----------------------------
        % Dependent property getters
        % -----------------------------

        function MaxVoltage_SinglePowerSupply = get.MaxVoltage_SinglePowerSupply(obj)
            MaxVoltage_SinglePowerSupply = obj.MaxVoltage_SinglePowerSupply_Private;
        end

        function MaxVoltage_TriplePowerSupply = get.MaxVoltage_TriplePowerSupply(obj)
            MaxVoltage_TriplePowerSupply = obj.MaxVoltage_TriplePowerSupply_Private;
        end

        function VoltageResolution = get.VoltageResolution(obj)
            VoltageResolution = obj.VoltageResolutionPrivate;
        end

        % -----------------------------
        % Set / Read Voltage & Current
        % -----------------------------

        function setVoltage(obj, voltage, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 3
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 3
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "set" command type
                cmd = obj.constructCommand('VOLT', voltage, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage set to %.2f V on Channel %d\n', ...
                        obj.CurrentSupplyName, voltage, channel);
                else
                    fprintf('[%s] Voltage set to %.2f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to set the voltage: %s', ME.message);
            end
        end

        function setCurrent(obj, current, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 3
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 3
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "set" command type
                cmd = obj.constructCommand('CURR', current, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current set to %.2f A on Channel %d\n', ...
                        obj.CurrentSupplyName, current, channel);
                else
                    fprintf('[%s] Current set to %.2f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to set the current: %s', ME.message);
            end
        end

        function voltage = readVoltage(obj, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 2
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 2
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "read" command type
                cmd = obj.constructCommand('MEAS:VOLT?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                voltageStr = fscanf(obj.InstrObj);
                voltage = str2double(voltageStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage on Channel %d: %.3f V\n', ...
                        obj.CurrentSupplyName, channel, voltage);
                else
                    fprintf('[%s] Voltage: %.3f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to read the voltage: %s', ME.message);
            end
        end

        function current = readCurrent(obj, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 2
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 2
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "read" command type
                cmd = obj.constructCommand('MEAS:CURR?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                currentStr = fscanf(obj.InstrObj);
                current = str2double(currentStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current on Channel %d: %.3f A\n', ...
                        obj.CurrentSupplyName, channel, current);
                else
                    fprintf('[%s] Current: %.3f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to read the current: %s', ME.message);
            end
        end

        % -----------------------------
        % Output ON / OFF
        % -----------------------------

        function powerOn(obj, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 2
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 2
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "power" command type
                cmd = obj.constructCommand('OUTP ON', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned ON for Channel %d\n', ...
                        obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned ON\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power on: %s', ME.message);
            end
        end

        function powerOff(obj, channel)
            % Handle optional channel argument
            if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                if nargin < 2
                    channel = []; % Not used for single supply
                end
            else
                if nargin < 2
                    error('Channel must be specified for TriplePowerSupply.');
                end
            end

            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "power" command type
                cmd = obj.constructCommand('OUTP OFF', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned OFF for Channel %d\n', ...
                        obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned OFF\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power off: %s', ME.message);
            end
        end

        % -----------------------------
        % Internal helpers
        % -----------------------------

        function cmd = constructCommand(obj, baseCmd, value, channel, commandType)
            % Helper function to construct SCPI commands with proper
            % channel handling for single vs triple supply.

            if nargin < 5
                error('Command type must be specified as "read", "power", or "set".');
            end

            % Validate channel number for TriplePowerSupply only
            if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                if isempty(channel) || ~ismember(channel, [1, 2, 3])
                    error('Invalid channel number. Valid channels are 1, 2, or 3.');
                end
            end

            switch commandType
                case 'read'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        % Example: "MEAS:VOLT?"
                        cmd = baseCmd;
                    else
                        % Example: "MEAS:VOLT? (@2)"
                        cmd = sprintf('%s (@%d)', baseCmd, channel);
                    end

                case 'set'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        % Example: "VOLT 5.00"
                        cmd = sprintf('%s %.2f', baseCmd, value);
                    else
                        % Example: "VOLT 12.00, (@2)"
                        cmd = sprintf('%s %.2f, (@%d)', baseCmd, value, channel);
                    end

                case 'power'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        % Example: "OUTP ON"
                        cmd = sprintf('%s', baseCmd);
                    else
                        % Example: "OUTP ON, (@2)"
                        cmd = sprintf('%s, (@%d)', baseCmd, channel);
                    end

                otherwise
                    error('Invalid command type. Use "read", "power", or "set".');
            end
        end

        function rscName = selectResource(obj, SupplyName)
            % SELECTRESOURCE Select the appropriate VISA resource string.

            % Define valid supply names
            validNames = obj.PossibleNames;

            % Check if the provided supply name is valid
            if ~ismember(SupplyName, validNames)
                errorMessage = sprintf('Invalid power supply name. Valid names are: %s', ...
                    strjoin(validNames, ', '));
                error(errorMessage);
            end

            % Select the appropriate resource string based on the valid supply name
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
