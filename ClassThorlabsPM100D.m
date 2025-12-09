classdef (Sealed) ClassThorlabsPM100D < handle
%Class for Thorlabs PM100D power meter, refer to the manual in
%Desktop->Instruments for SCPI commands. To connect to different power
%meter of same model, read and change the USB-VISA address in the class

    properties (Access = public)
        Public_Handle
    end
    
    properties (Access = private)
        %the one on the optical head adress: 'USB0::0x1313::0x8078::P0007699::INSTR'
        PM_Handle
        VisaName_OpticalHeadOne = 'USB0::0x1313::0x8078::P0045229::0::INSTR';
        wavelength = 930;
    end
    
    properties (Dependent = true)
    end
    
    methods (Access = private)
        function obj = ClassThorlabsPM100D()
        end
    end
    
    
    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassThorlabsPM100D;
            end
            obj = localObj;
        end
    end
    
    methods
        function connect(obj)
            
            if isempty(obj.PM_Handle)
                obj.PM_Handle = visa('agilent', obj.VisaName_OpticalHeadOne);
            end
            if isempty(obj.PM_Handle)
                error('failed to open: %s.', obj.VisaName_OpticalHeadOne);
            end
            
            try
                fclose(obj.PM_Handle);
            catch
            end
            fopen(obj.PM_Handle);
            InstrID = query(obj.PM_Handle,'*IDN?');
            InstrID = InstrID(1:end-1); % There is Carrier return symbol end of returned value
            if ~contains(InstrID, 'PM100D')
                fprintf([InstrID,' found','\n']);
                fclose(obj.PM_Handle);
                error('Could not open or find Thorlabs PM100D!')
            end
            SensorName = query(obj.PM_Handle,'SYST:SENS:IDN?');
            SensorName = SensorName(1:end-1);
            fprintf(['Connected to  ',InstrID,' with sensor: ',SensorName,'.\n']);
            obj.PM_Handle.Timeout = 1;
            obj.Public_Handle = obj.PM_Handle;
        end
        function CloseConnection(obj)
            try
                flushinput(obj.PM_Handle);
                flushoutput(obj.PM_Handle);
            catch
            end
            fclose(obj.PM_Handle);
            fprintf('Connection to Thorlabs PM100D closed.\n');
        end
        
        function Power = GetPower(obj)
            % Unit in W
%             fprintf(obj.PM_Handle,'INIT');
%             PowerStr = query(obj.PM_Handle,'FETCh?');
            %PowerStr = query(obj.PM_Handle,'READ?');
            PowerStr = query(obj.PM_Handle, 'MEASure?');
            PowerStr = PowerStr(1:end-1);
            Power = str2num(PowerStr);
            %fprintf(obj.PM_Handle,'ABORt');
        end
        
        function SetWavelength(obj,wavelength)
            fprintf(obj.PM_Handle,['SENS:CORR:WAV ', num2str(round(wavelength))]);
            wav = query(obj.PM_Handle, 'SENS:CORR:WAV?');
            wav = wav(1:end-1);
            wav = str2num(wav);
            if (round(wavelength)-wav)>1
                error('Could not complete wavelength setting!');
            end
        end
        
        function wav = GetWavelength(obj)
            wavstr = query(obj.PM_Handle, 'SENS:CORR:WAV?');
            wavstr = wavstr(1:end-1);
            wav = str2num(wavstr);
         end
                
    end
    
   
end
