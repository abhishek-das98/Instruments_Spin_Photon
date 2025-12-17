classdef (Sealed) ClassMagnetNew < handle
    % ClassMagnetNew (USB Serial, single-channel)
    %   Control APS100 over USB serial (COM port) using MATLAB serialport.
    %   No VISA required. Designed for single-channel controller.

    properties (Dependent = true)
        Field_T
        OutputCurrent_A
        MagnetVoltage_V
        OutputVoltage_V
        UpperLimit_T
        LowerLimit_T
        HeaterIsOn
        SweepStatus
    end

    properties (Access = private)
        % ---- Connection settings ----
        ComPort    = "COM4";      % <-- change to your COM port
        BaudRate   = 115200;      % from your front panel
        Terminator = "LF";        % try "LF" first; if issues, try "CR/LF"
        Timeout_s  = 10;

        InstrObj                 % serialport handle

        % ---- Command timing ----
        UploadTimeOut   = 60;
        WaitTimeCommand = 0.2;

        % ---- Units / safety ----
        UnitModeField = "G";      % we force UNITS G on connect
        MaxField_T    = 9.0;      % software safety limit
    end

    methods (Access = private)
        function obj = ClassMagnetNew()
        end
    end

    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassMagnetNew();
            end
            obj = localObj;
        end
    end

    %% Connection
    methods
        function SetComPort(obj, comStr)
            obj.ComPort = string(comStr);
        end

        function Connect(obj)
            obj.CloseConnection();

            obj.InstrObj = serialport(obj.ComPort, obj.BaudRate, "Timeout", obj.Timeout_s);
            configureTerminator(obj.InstrObj, obj.Terminator);
            flush(obj.InstrObj);

            idn = obj.QueryDevice("*IDN?");
            fprintf("APS100 IDN: %s\n", idn);

            % ---- REQUIRED for USB control ----
            % Take remote control. If the APS100 is in LOCAL or in a menu, REMOTE will be rejected.
            obj.SendCmd("REMOTE");

            % Enable error messages temporarily for debugging (set to 0 later if you prefer)
            obj.SendCmd("ERROR 1");

            % Set field units
            obj.SendCmd("UNITS G");
        end


        function CloseConnection(obj)
            try
                if ~isempty(obj.InstrObj)
                    flush(obj.InstrObj);
                    clear obj.InstrObj;
                end
            catch
            end
            obj.InstrObj = [];
        end
    end

    %% Dependent property getters
    methods
        function v = get.Field_T(obj),          v = obj.ReadField();          end
        function v = get.OutputCurrent_A(obj),  v = obj.ReadOutputCurrent();  end
        function v = get.MagnetVoltage_V(obj),  v = obj.ReadMagnetVoltage();  end
        function v = get.OutputVoltage_V(obj),  v = obj.ReadOutputVoltage();  end
        function v = get.UpperLimit_T(obj),     v = obj.ReadUpperLimit();     end
        function v = get.LowerLimit_T(obj),     v = obj.ReadLowerLimit();     end
        function v = get.HeaterIsOn(obj),       v = logical(obj.ReadHeaterState()); end
        function s = get.SweepStatus(obj),      s = obj.ReadSweepStatus();    end
    end

    %% Low-level helpers
    methods (Access = private)
        function ensureConnected(obj)
            if isempty(obj.InstrObj)
                error("ClassMagnetNew:NotConnected", "Call Connect() first.");
            end
        end

        function reply = QueryDevice(obj, cmd)
            obj.ensureConnected();
            flush(obj.InstrObj);

            cmd = string(cmd);
            writeline(obj.InstrObj, cmd);

            % Read up to a few lines; skip echoes like "*IDN?"
            maxLines = 5;
            reply = "";

            for k = 1:maxLines
                line = strtrim(string(readline(obj.InstrObj)));

                % If instrument echoes the command, ignore that line
                if strcmpi(line, strtrim(cmd))
                    continue;
                end

                % First non-echo line is our reply
                reply = line;
                return;
            end

            error("ClassMagnetNew:NoReply", ...
                "No valid reply received for '%s' (only echo / nothing).", cmd);
        end


        function SendCmd(obj, cmd)
            obj.ensureConnected();
            flush(obj.InstrObj);
            writeline(obj.InstrObj, string(cmd));
            obj.WaitOperationComplete();
        end

        function WaitOperationComplete(obj)
            t0 = tic;
            while true
                r = strtrim(obj.QueryDevice("*OPC?"));
                val = str2double(r);
                if ~isnan(val) && val == 1
                    return;
                end
                if toc(t0) > obj.UploadTimeOut
                    error("ClassMagnetNew:OPCTimeout", "*OPC? timeout after %.1f s.", obj.UploadTimeOut);
                end
                pause(obj.WaitTimeCommand);
            end
        end

        function [val, unitStr] = parseValueWithUnits(~, reply)
            reply = strtrim(reply);
            tok = regexp(reply, ...
                '([-+]?\d*\.?\d+(?:[Ee][-+]?\d+)?)\s*([A-Za-z]*)', ...
                'tokens', 'once');
            if isempty(tok)
                error("ClassMagnetNew:ParseError", "Cannot parse reply: '%s'", reply);
            end
            val = str2double(tok{1});
            unitStr = string(tok{2});
        end

        function scale = unitToTeslaScale(~, unitStr)
            u = upper(strtrim(unitStr));
            switch u
                case {"G","GAUSS",""}   % some replies omit unit
                    scale = 1e-4;
                case {"KG","KGAUSS"}
                    scale = 1e-1;
                case {"T","TESLA"}
                    scale = 1.0;
                otherwise
                    error("ClassMagnetNew:UnknownFieldUnit", "Unknown unit '%s'.", u);
            end
        end

        function instVal = teslaToConfiguredField(obj, fieldT) % Ignore the warning
            % APS100 expects field inputs in kG when UNITS = G
            % 1 Tesla = 10 kG
            instVal = fieldT * 10.0;
        end

    end

    %% Public high-level API
    methods
        % Heater
        function st = ReadHeaterState(obj)
            st = str2double(strtrim(obj.QueryDevice("PSHTR?")));
        end
        function HeaterOn(obj),  obj.SendCmd("PSHTR ON");  end
        function HeaterOff(obj), obj.SendCmd("PSHTR OFF"); end

        % Reads
        function fieldT = ReadField(obj)
            [val, unitStr] = obj.parseValueWithUnits(obj.QueryDevice("IMAG?"));
            fieldT = val * obj.unitToTeslaScale(unitStr);
        end
        function I = ReadOutputCurrent(obj)
            [val, ~] = obj.parseValueWithUnits(obj.QueryDevice("IOUT?"));
            I = val;
        end
        function V = ReadMagnetVoltage(obj)
            [val, ~] = obj.parseValueWithUnits(obj.QueryDevice("VMAG?"));
            V = val;
        end
        function V = ReadOutputVoltage(obj)
            [val, ~] = obj.parseValueWithUnits(obj.QueryDevice("VOUT?"));
            V = val;
        end

        % Set field
        function SetField(obj, fieldT)
            if abs(fieldT) > obj.MaxField_T
                fprintf("Requested %.3f T exceeds limit %.3f T. Not executed.\n", fieldT, obj.MaxField_T);
                return;
            end
            instVal = obj.teslaToConfiguredField(fieldT);
            obj.SendCmd(sprintf("IMAG %.6f", instVal));
        end

        % Limits
        function uT = ReadUpperLimit(obj)
            [val, unitStr] = obj.parseValueWithUnits(obj.QueryDevice("ULIM?"));
            uT = val * obj.unitToTeslaScale(unitStr);
        end
        function lT = ReadLowerLimit(obj)
            [val, unitStr] = obj.parseValueWithUnits(obj.QueryDevice("LLIM?"));
            lT = val * obj.unitToTeslaScale(unitStr);
        end
        function SetUpperLimit(obj, fieldT)
            instVal = obj.teslaToConfiguredField(fieldT);
            obj.SendCmd(sprintf("ULIM %.6f", instVal));
        end
        function SetLowerLimit(obj, fieldT)
            instVal = obj.teslaToConfiguredField(fieldT);
            obj.SendCmd(sprintf("LLIM %.6f", instVal));
        end

        % Sweeps
        function Zero(obj, useFast)
            if nargin < 2 || ~useFast, obj.SendCmd("SWEEP ZERO");
            else,                      obj.SendCmd("SWEEP ZERO FAST");
            end
        end
        function GoToUpperField(obj, useFast)
            if nargin < 2 || ~useFast, obj.SendCmd("SWEEP UP");
            else,                      obj.SendCmd("SWEEP UP FAST");
            end
        end
        function GoToLowerField(obj, useFast)
            if nargin < 2 || ~useFast, obj.SendCmd("SWEEP DOWN");
            else,                      obj.SendCmd("SWEEP DOWN FAST");
            end
        end
        function PauseSweep(obj), obj.SendCmd("SWEEP PAUSE"); end
        function s = ReadSweepStatus(obj), s = strtrim(obj.QueryDevice("SWEEP?")); end
    end
end
