classdef (Sealed) ClassMagnetNew < handle
    % ClassMagnetNew
    %   Singleton wrapper for APS100 Magnet Power Supply
    %   External interface uses magnetic field in Tesla where possible
    %   Internally the supply is set tp field units (Gauss)

    % Dependent properties 
    properties (Dependent = true)
        Field_T          % Magnetic field in Tesla (from IMAG?)
        OutputCurrent_A  % Supply output current in A (from IOUT?)
        MagnetVoltage_V  % Magnet voltage in V (from VMAG?)
        OutputVoltage_V  % Supply output voltage in V (from VOUT?)
        UpperLimit_T     % Upper sweep limit in Tesla
        LowerLimit_T     % Lower sweep limit in Tesla
        VoltageLimit_V   % Output voltage limit in V
        HeaterIsOn       % True if persistent heater ON
        SweepStatus      % Text description of the sweep rate
    end

    % Private, fixed settings 
    properties (Access = private)
        % GPIB board index and device address
        GPIBBoard   = 0;  % NI Board Index
        GPIBAddress = 1;  % APS100 device address (set to match front panel GPIB ID)

        InstrObj               % GPIB objext handle
        UploadTimeOut   = 60;  % General timeout for VISA ops (s)
        WaitTimeCommand = 0.2  % Poll interval when waiting for *OPC?

        % Units / conversion
        UnitModeField  = 'G';  % We set APS100 to field units "G" (Gauss)
        MaxField_T       = 9.0;  % Software limit in Tesla
    end

    % Singleton constructor
    methods (Access = private)
        function obj = ClassMagnetNew()
        end
    end

    % Singleton accessor
    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassMagnetNew();
            end
            obj = localObj;
        end
    end

    % Connection handling
    methods
        function connect(obj)
            % Open GPIB connection and put supply into a known state

            if isempty(obj.InstrObj) || ~isvalid(obj.InstrObj)
                obj.InstrObj = gpib('ni', obj.GPIBBoard, obj.GPIBAddress);
            end
            if isempty(obj.InstrObj) || ~isvalid(obj.InstrObj)
                error('ClassMagnetNew:ConnectionFailed', ...
                    'Failed to create GPIB object for address %d.', obj.GPIBAddress);
            end

            % Make sure it is closed before reopening
            try
                fclose(obj.InstrObj);
            catch
            end

            set(obj.InstrObj, 'OutputBufferSize', 1e6);
            set(obj.InstrObj, 'Timeout', obj.UploadTimeOut);

            fopen(obj.InstrObj);

            % Identify instrument
            idn = strtrim(obj.QueryDevice('*IDN?'));
            fprintf('APS100 IDN: %s\n', idn);

            obj.SendCmd('Units G');
        end

        function CloseConnection(obj)
            % Close GPIB link
            if ~isempty(obj.InstrObj) && isvalid(obj.InstrObj)
                try
                    fclose(obj.InstrObj);
                    fprintf('APS100 connection closed.\n');
                catch
                end
            end
        end

        function SysError(obj, msg)
            % Helper to close and throw a MATLAB error
            obj.CloseConnection();
            error('ClassMagnetNew:SysError', '%s', msg);
        end
    end

        % Low-level SCPI helpers
        methods (Access = private)
            function result = QueryDevice(obj, cmd)
                % Issue a SCPI query and return trimmed string
                result = strtrim(query(obj.InstrObj, cmd));
            end

            function WaitOperationComplete(obj)
                % Poll *OPC? until all pending operations complete
                while true
                    reply = strtrim(query(obj.InstrObj, '*OPC?'));
                    val = str2double(reply);
                    if ~isnan(val) && val == 1
                        break;
                    end
                    pause(obj.WaitTimeCommand);
                end
            end

            function SendCmd(obj, varargin)
                % Send a SCPI command and wait for completion
                if numel(varargin) > 1
                    scpi_str = strjoin(varargin, ' ');
                else
                    scpi_str = varargin{1};
                end
                fprintf(obj.InstrObj, scpi_str);
                obj.WaitOperationComplete();
            end

            function [val, unitStr] = parseValueWithUnits(~, reply)
                % Parse "<value> <units>" from APS100 responses.
                reply = strtrim(reply);
                tokens = regexp(reply, ...
                    '([-+]?\d*\.?\d+(?:[Ee][-+]?\d+)?)\s*([A-Za-z]*)', ...
                    'tokens', 'once');
                if isempty(tokens)
                    error('ClassMagnetNew:ParseError', ...
                        'Could not parse numeric value from "%s".', reply);
                end
                val     = str2double(tokens{1});
                unitStr = tokens{2};
            end

            function scale = unitToTeslaScale(~, unitStr)
                % Convert APS100 field units to Tesla
                unitStr = upper(strtrim(unitStr));
                switch unitStr
                    case {'G', 'GAUSS'}
                        scale = 1e-4;  % 1 G = 1e-4 T
                    case {'KG', 'KGAUSS'}
                        scale = 1e-1;  % 1 kG = 0.1 T
                    case {'T', 'TESLA'}
                        scale = 1.0;
                    otherwise
                        error('ClassMagnetNew:UnknownFieldUnit', ...
                            'Unknown field unit "%s".', unitStr);
                end
            end

            function valField = teslaToConfiguredField(obj, fieldT)
                % Convert Tesla to instrument field units (we set UNITS G);
                switch upper(obj.UnitModeField)
                    case 'G'
                        valField = fieldT / 1e-4;  % Tesla -> Gauss
                    otherwise
                        error('ClassMagnetNew:UnsupportedUnitMode', ...
                            'UnitModeField "%s" not supported.' obj.UnitModeField);
                end
            end
        end

            % Dependent property getters
            methods
                function v = get.Field_T(obj)
                    v = obj.ReadField();
                end

                function v = get.OutputCurrent_A(obj)
                    v = obj.ReadOutputCurrent();
                end

                function v = get.MagnetVoltage_V(obj)
                    v = obj.ReadMagnetVoltage();
                end

                function v = get.OutputVoltage_V(obj)
                    v = obj.ReadOutputVoltage();
                end

                function v = get.UpperLimit_T(obj)
                    v = obj.ReadUpperLimit();
                end

                function v = get.LowerLimit_T(obj)
                    v = obj.ReadLowerLimit();
                end

                function v = get.VoltageLimit_V(obj)
                    v = obj.ReadVoltageLimit();
                end

                function v = get.HeaterIsOn(obj)
                    v = logical(obj.ReadHeaterState());
                end

                function s = get.SweepStatus(obj)
                    s = obj.ReadSweepStatus();
                end
            end

            % High-level magnet control API
            methods
                % ----- Heater -----
                function state = ReadHeaterState(obj)
                    % 0 = OFF, 1 = ON
                    reply = obj.QueryDevice('PSHTR?');
                    state = str2double(reply);  % returns 0 or 1
                end

                function HeaterOn(obj)
                    % Turn persistent switch heater ON
                    obj.SendCmd('PSHTR ON');
                end

                function HeaterOff(obj)
                    % Turn persistent switch heater OFF
                    obj.SendCmd('PSHTR OFF');
                end

                % ----- Field / current -----
                function fieldT = ReadField(obj)
                    % Magnet field in Tesla, using IMAG?
                        [val, units] = obj.parseValueWithUnits(obj.QueryDevice('IMAG?'));
                        fieldT = val * obj.unitToTeslaScale(units);
                end

                function currentA = ReadOutputCurrent(obj)
                    % Power supply output current in Amps (IOUT?)
                    [val, ~] = obj.parseValueWithUnits(obj.QueryDevice('IOUT?'));
                    currentA = val;
                end

                function SetField(obj, fieldT)
                    % Set target magnet field in Tesla via IMAG
                    if abs(fieldT) > obj.MaxField_T
                        fprintf(['Requested field %.3f T exceeds software limit %.3f T.', ...
                            'Command not executed.\n'], fieldT, obj.MaxField_T);
                        return;
                    end

                    fieldUnitVal = obj.teslaToConfiguredField(fieldT);
                    cmd = sprintf('IMAG %.6f', fieldUnitVal);
                    obj.SendCmd(cmd);
                end

                function SetCurrent(obj, currentA)
                    % Alternative: set magnet current directly in Amps.
                    % Temporarily switch to A units, set, then restore field units.
                    prevUnits = strtrim(obj.QueryDevice('UNITS?'));
                    if ~strcmpi(prevUnits, 'A')
                        obj.SendCmd('UNITS A');
                    end
                    cmd = sprintf('IMAG %.6f', currentA);
                    obj.SendCmd(cmd);
                    if ~strcmpi(prevUnits, 'A')
                        obj.SendCmd(['UNITS ' prevUnits]);
                    end
                end

                % ----- Limits -----
                function ulimT = ReadUpperLimit(obj)
                    % Upper sweep limit in Tesla
                    [val, units] = obj.parseValueWithUnits(obj.QueryDevice('ULIM?'));
                    ulimT = val * obj.unitToTeslaScale(units);
                end

                function llimT = ReadLowerLimit(obj)
                    % Lower sweep limit in Tesla
                    [val, units] = obj.parseValueWithUnits(obj.QueryDevice('LLIM?'));
                    llimT = val * obj.unitToTeslaScale(units);
                end

                function SetUpperLimit(obj, fieldT)
                    % Set upper sweep limit in Tesla (ULIM)
                    if abs(fieldT) > obj.MaxField_T
                        fprintf(['Upper limit %3f T exceeds software limit %.3f T',  ...
                            'Command not executed.\n'], fieldT, obj.MaxField_T);
                        return;
                    end
                    fieldUnitVal = obj.teslaToConfiguredField(fieldT);
                    cmd = sprintf('ULIM %.6f', fieldUnitVal);
                    obj.SendCmd(cmd);
                end

                function SetLowerLimit(obj, fieldT)
                    % Set lower sweep limit in Tesla (LLIM)
                    if abs(fieldT) > obj.MaxField_T
                        fprintf(['Lower limit %.3f T exceeds software limit %.3f T', ...
                            'Command not executed.\n'], fieldT, obj.MaxField_T);
                        return;
                    end
                    fieldUnitVal = obj.teslaToConfiguredField(fieldT);
                    cmd = sprintf('LLIM %.6f', fieldUnitVal);
                    obj.SendCmd(cmd);
                end

                % ----- Voltage -----
                function v = ReadMagnetVoltage(obj)
                    % Magnet voltage at Mag.Vin terminals (VMAG?).
                    [val, ~] = obj.parseValueWithUnits(obj.QueryDevice('VMAG?'));
                    v = val;
                end

                function v = ReadOutputVoltage(obj)
                    % Power supply output voltage at terminals (VOUT?)
                    [val, ~] = obj.parseValueWithUnits(obj.QueryDevice('VOUT?'));
                    v = val;
                end

                function v = ReadVoltageLimit(obj)
                    % Output voltage limit (VLIM?)
                    [val, ~] = obj.parseValueWithUnits(obj.QueryDevice('VLIM?'));
                    v = val;
                end

                function SetVoltageLimit(obj, vLimit)
                    % Set output voltage limit in Volts
                    cmd = sprintf('VLIM %.4f', vLimit);
                    obj.SendCmd(cmd);
                end

                % ----- Sweeping -----
                function Zero(obj, useFast)
                    % Sweep to zero current
                    if nargin < 2 || ~useFast
                        obj.SendCmd('SWEEP ZERO');
                    else 
                        obj.SendCmd('SWEEP ZERO FAST');
                    end
                end

                function GoToUpperField(obj, useFast)
                    % Sweep to upper limit (ULIM)
                    if nargin < 2 || ~useFast
                        obj.SendCmd('SWEEP UP');
                    else
                        obj.SendCmd('SWEEP UP FAST');
                    end
                end

                function GoToLowerField(obj, useFast)
                    % Sweep to lower limit (LLIM)
                    if nargin < 2 || ~useFast
                        obj.SendCmd('SWEEP DOWN');
                    else
                        obj.SendCmd('SWEEP DOWN FAST');
                    end
                end

                function PauseSweep(obj)
                    % Pause an active sweep
                    obj.SendCmd('SWEEP PAUSE');
                end

                function modeStr = ReadSweepStatus(obj)
                    % Return textual sweep status (SWEEP?)
                    modeStr = obj.QueryDevice('SWEEP?'); %e.g. 'sweep up fast'
                end

                % ----- Misc -----
                function name = GetCoilName(obj)
                    % Read coil (module) name string
                    name = obj.QueryDevice('NAME?');
                end

                function SetCoilName(obj, name)
                    % Set coil (module) name string (max 16 chars)
                    name = upper(name);
                    obj.SendCmd(['NAME ' name]);
                end
                
                function ResetQuench(obj)
                    % Clear quench condition and return to STANDBY
                    obj.SendCmd('QRESET');
                end
            end
end