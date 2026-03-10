classdef (Sealed) ClassPicoharp <  handle % cannot be inherited
    % Class for operating the keysight AWG
    %   Detailed explanation goes here
    properties (Dependent = true)
        %Picoharp settings
        ZeroCr0
        ZeroDiscr0
        ZeroDivider0
        Offset0
        ZeroOffset0
        ZeroCr1
        ZeroDiscr1
        Resolution
        Block % To save memory in the picoharp hardware, in this implementation the 'Block' parameter changes the histogram acquisition index in Matlab only and not in the picoharp hardware itself 
        Mode
        Offset
        TimeStop
        CountStop   
    end
    
    properties (Access = private)

        
        % Library properties 
        LibName='PHlib';
        DllFileName='PHLib64.dll';
        HFileName='phlib.h';
        LibraryType='alias';
        
        DevIdx=0; % For single picoharp used, device index should be 0
    
        REQLIBVER   =  '3.0'; %library version for the program
        PH_ERROR_DEVICE_OPEN_FAIL = -1; %value representing a picoharp opening error 
        MODE_HIST   =      0; %Histogram mode parameter
        HISTCHAN    =  65536;	    % number of histogram channels
        FLAG_OVERFLOW = hex2dec('0040'); %overflow value for getting a histogram
        
        %Device specifications
        BaseResolution=4; % the highest resolution of the picoharp in picoseconds
        ResVals=[4,8,16,32,64,128,256,512]; %possible resolutions in ps
        TimeStopMax=360000; %Maximal total accumulation time in seconds
        CountStopMax=65535; %Maximal total accumulated counts
        SyncChannelNumber=0; %channel number of sync signal is 0

        
        %Default Settings (values can be changed by user)
        ZeroCr0Private=10;
        ZeroDiscr0Private=50;
        ZeroDivider0Private=0; %='None'?
        ZeroOffset0Private=0;
        ZeroCr1Private=10;
        ZeroDiscr1Private=50;
        ResolutionPrivate=4;
        BlockPrivate=0;
        OffsetPrivate=0;
        TimeStopPrivate=360000;
        CountStopPrivate=65535;
        ModePrivate='INT';
        
        
    end
    
    methods
        % Getting the Picoharp parameters
        function ZeroCr0=get.ZeroCr0(obj)
            ZeroCr0=obj.ZeroCr0Private;
        end
        function ZeroDiscr0=get.ZeroDiscr0(obj)
            ZeroDiscr0=obj.ZeroDiscr0Private;
        end
        function ZeroDivider0=get.ZeroDivider0(obj)
            ZeroDivider0=obj.ZeroDivider0Private;
        end
        function ZeroOffset0=get.ZeroOffset0(obj)
            ZeroOffset0=obj.ZeroOffset0Private;
        end
        function ZeroCr1=get.ZeroCr1(obj)
            ZeroCr1=obj.ZeroCr1Private;
        end
        function ZeroDiscr1=get.ZeroDiscr1(obj)
            ZeroDiscr1=obj.ZeroDiscr1Private;
        end
        function Resolution=get.Resolution(obj)
            Resolution=obj.ResolutionPrivate;
        end
        function Block=get.Block(obj)
            Block=obj.BlockPrivate;
        end
        function Offset=get.Offset(obj)
            Offset=obj.OffsetPrivate;
        end
        function TimeStop=get.TimeStop(obj)
            TimeStop=obj.TimeStopPrivate;
        end
        function CountStop=get.CountStop(obj)
            CountStop=obj.CountStopPrivate;
        end
        function Mode=get.Mode(obj)
            Mode=obj.ModePrivate;
        end
        
        % Functions for changing the parameters containing the picoharp settings
        function SetZeroCr0(obj,new)
            obj.ZeroCr0Private=new;
        end
        function SetZeroDiscr0(obj,new)
            obj.ZeroDiscr0Private=new;
        end
        function SetZeroDivider0(obj,new)
            obj.ZeroDivider0Private=new;
        end
        function SetZeroOffset0(obj,new)
            obj.ZeroOffset0Private=new;
        end
        function SetZeroCr1(obj,new)
            obj.ZeroCr1Private=new;
        end
        function SetZeroDiscr1(obj,new)
            obj.ZeroDiscr1Private=new;
        end
        function SetResolution(obj,new)
            if ~(any(obj.ResVals==new))
                X=['The only possible resolutions are ' mat2str(obj.ResVals) ' picoseconds. Did not update.\n'];
                fprintf(X);
            else
            obj.ResolutionPrivate=new;
            end
        end
        function SetBlock(obj,new)
            obj.BlockPrivate=new;
        end
        function SetOffset(obj,new)
            obj.OffsetPrivate=new;
        end
        function SetTimeStop(obj,new)
            if (new>obj.TimeStopMax)
                X=['Time limit cannot exceed ' num2str(obj.TimeStopMax) ' seconds. Did not update.\n'];
                fprintf(X);
            else
            obj.TimeStopPrivate=new;
            end
        end
        function SetCountStop(obj,new)
            if (new>obj.CountStopMax)
                X=['Count limit cannot exceed ' num2str(obj.CountStopMax) '. Did not update.\n'];
                fprintf(X);
            else 
                obj.CountStopPrivate=new;
            end
        end
        function SetMode(obj,new)
            obj.ModePrivate=new;
        end    
    end
    
    methods (Access = private)
        function obj = ClassPicoharp()
        end
    end
    
    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassPicoharp;
            end
            obj = localObj;
        end
    end
    
    methods
        
        
        function CloseConnection(obj)
            fprintf('\nclosing all PicoHarp devices\n');
            if (libisloaded(obj.LibName))
                calllib('PHlib', 'PH_CloseDevice', obj.DevIdx);
            end
        end
        
        function CheckError(obj,message,ret)
            if(ret<0)
                obj.CloseConnection;
                error([message ', err %d, aborted \n'],ret);
            end
        end
        
        function SetParams(obj)
           % Sets the picoharp parameters according to the values in 'obj'
           [ret] = calllib(obj.LibName, 'PH_SetSyncOffset', obj.DevIdx, obj.ZeroOffset0);
           obj.CheckError('\nPH_SetSyncOffset error',ret);

           [ret] = calllib(obj.LibName, 'PH_SetInputCFD', obj.DevIdx, 0, obj.ZeroDiscr0, obj.ZeroCr0);
           obj.CheckError('\nPH_SetInputCFD error',ret);
           
           [ret] = calllib(obj.LibName, 'PH_SetInputCFD', obj.DevIdx, 1, obj.ZeroDiscr1, obj.ZeroCr1);
           obj.CheckError('\nPH_SetInputCFD error',ret);
           
           % Binning 0 -> Resolution = base, Binning 1-> Resolution = 2^1*base, Binning 2-> Resolution= 2^2*base etc 
           Binning=log2(obj.Resolution./obj.BaseResolution);
           [ret] = calllib(obj.LibName, 'PH_SetBinning', obj.DevIdx, Binning);
           obj.CheckError('\nPH_SetBinning error',ret);
           
           [ret] = calllib(obj.LibName, 'PH_SetOffset', obj.DevIdx, obj.Offset);
           obj.CheckError('\nPH_SetOffset error',ret);

           ret = calllib(obj.LibName, 'PH_SetStopOverflow', obj.DevIdx, 1, obj.CountStop);
           obj.CheckError('\nPH_SetStopOverflow error',ret);
           
           ResolutionFromDevice = 0; 
           ResolutionPtr = libpointer('doublePtr', ResolutionFromDevice);
           [ret, ResolutionFromDevice] = calllib(obj.LibName, 'PH_GetResolution', obj.DevIdx, ResolutionPtr);
           obj.CheckError('\nPH_GetResolution error',ret);
           if (ResolutionFromDevice~=obj.Resolution) %check if the resolution read from the device is identical to the one specified by the user
               error('Resolution setting error. Aborted.\n');
           end
           
            % Note: after Init or SetSyncDiv you must allow 100 ms for valid new count rate readings
            pause(0.2);

            %Save the acquisition settings in a file with a name corresponding to the block
            %number...
            filename=['SettingsChannel' num2str(obj.Block) '.out'];
            fid = fopen(filename,'w');
            obj.CheckError('Cannot open output file',ret);
            
            fprintf(fid,'Binning          : %ld\n',Binning);
            fprintf(fid,'Resolution          : %ld\n',ResolutionFromDevice);
            fprintf(fid,'Offset           : %ld\n',obj.Offset);
            fprintf(fid,'AcquisitionTime  : %ld\n',obj.TimeStop);
            fprintf(fid,'SyncDivider      : %ld\n',obj.ZeroDivider0);
            fprintf(fid,'SyncOffset       : %ld\n',obj.ZeroOffset0);
            fprintf(fid,'CFDZeroCross0    : %ld\n',obj.ZeroCr0);
            fprintf(fid,'CFDLevel0        : %ld\n',obj.ZeroDiscr0);
            fprintf(fid,'CFDZeroCross1    : %ld\n',obj.ZeroCr1);
            fprintf(fid,'CFDLevel1        : %ld\n',obj.ZeroDiscr1);
            fclose(fid);
        end
        
        function connect(obj) 
            % connect and initialize picoharp
            % load picoharp library

            if (~libisloaded(obj.LibName))
                loadlibrary(obj.DllFileName, obj.HFileName, obj.LibraryType, obj.LibName);
            else
                fprintf('Note: PHlib was already loaded\n');
            end
            if (libisloaded(obj.LibName))
                fprintf('Library opened successfully\n');
                %libfunctionsview('PHlib'); %use this to test for proper loading
            else
                fprintf('Could not open Library\n');
                return;
            end
            
            % check that the library version installed is compatible with
            % the program
            LibVersion    = '????'; %enough length!
            LibVersionPtr = libpointer('cstring', LibVersion);
            
            [ret, LibVersion] =calllib(obj.LibName, 'PH_GetLibraryVersion', LibVersionPtr);
            obj.CheckError('Error in GetLibVersion',ret);
            fprintf('PHLib version is %s\n', LibVersion);
            
            if ~strcmp(LibVersion,obj.REQLIBVER)
                error('This program requires PHLib version %s\n', obj.REQLIBVER);
            end
            
            
            %Load picoharp device
            fprintf('\nSearching for PicoHarp devices...');
            
            dev = [];
            Serial     = '12345678'; %enough length!
            SerialPtr  = libpointer('cstring', Serial);
            ErrorStr   = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; %enough length!
            ErrorPtr   = libpointer('cstring', ErrorStr);
            
            [ret, Serial] = calllib(obj.LibName, 'PH_OpenDevice', 0, SerialPtr);
            if (ret==0)       % Grab any PicoHarp we successfully opened
                fprintf('\n         S/N %s',Serial);
            else
                if(ret==obj.PH_ERROR_DEVICE_OPEN_FAIL)
                    obj.CheckError('no device',ret);
                else
                    [ret, ErrorStr] = calllib(obj.LibName, 'PH_GetErrorString', ErrorPtr, ret);
                    obj.CheckError('ErrorStr',ret);
                end
            end
            
            % Initializing the device
            fprintf('\nInitializing the device...\n');
            
            [ret] = calllib(obj.LibName, 'PH_Initialize', obj.DevIdx, obj.MODE_HIST);
            obj.CheckError('\nPH init error',ret); 
            
            % Setting initial parameters and writing saving the settings a file
            obj.SetParams();
            %
        end
        
        
        function count=ReadCounter(obj,channel)
            % reads the total amount of counts in channel within the
            % defined resolution time
            count = 0;
            CountratePtr = libpointer('int32Ptr', count);
            [ret, count] = calllib(obj.LibName, 'PH_GetCountRate', obj.DevIdx,channel,CountratePtr);
            obj.CheckError('Counting error',ret);
            count=double(count);
        end
        
        function rate=GetSyncRate(obj)
            % gets the rate of the sync signal in MHz
            rate = obj.ReadCounter(obj.SyncChannelNumber);
        end
        
        function StopAcquisition(obj)
            % This function stops acquiring a histogram
            ret = calllib(obj.LibName, 'PH_StopMeas', obj.DevIdx);
            obj.CheckError('\nPH_StopMeas error',ret);

        end
        
        function ResumeAcquisition(obj,T)
            % Resume acquisition that has been started and paused, continue
            % for time T
            ret = calllib(obj.LibName, 'PH_StartMeas', obj.DevIdx,T*1000); %Obj.TimeStop is in seconds but the command's argument is in milliseconds
            obj.CheckError('\nPH_StartMeas error',ret);
            end

        
        function StartAcquisition(obj)
            % This function starts acquiring a histogram
            %update all the recent picoharp parameters required for the acquisition
            
            obj.SetParams(); 
            
            %Clear histogram memory
            
            ret = calllib(obj.LibName, 'PH_ClearHistMem', obj.DevIdx,0);    % The last parameter is the block. In this implementation, the routing is in the Matlab software so we always use block 0 of the picoharp. 
            obj.CheckError('\nPH_ClearHistMem error',ret);
            
            %Start acquisition
            obj.ResumeAcquisition(obj.TimeStop);
            
            fprintf('Measuring for %1d seconds\n',obj.TimeStop);
                       
        end
        
        function [TimesVec,hist]=GetHistogram(obj)
            %This function returns the data histogram versus time in
            %nanoseconds
            
            countsbuffer  = uint32(zeros(1,obj.HISTCHAN)); 
            bufferptr = libpointer('uint32Ptr', countsbuffer);
            [ret,countsbuffer] = calllib(obj.LibName, 'PH_GetHistogram', obj.DevIdx, bufferptr, 0); % The last parameter is the block. In this implementation, the routing is in the Matlab software so we always use block 0 of the picoharp. 
            obj.CheckError('\nPH_GetHistogram error',ret);
            
            flags = int32(0);
            flagsPtr = libpointer('int32Ptr', flags);
            [ret,flags] = calllib(obj.LibName, 'PH_GetFlags', obj.DevIdx, flagsPtr);
            obj.CheckError('\nPH_GetFlags error',ret);
            
            if(bitand(uint32(flags),obj.FLAG_OVERFLOW))
                fprintf('  Overflow.');
            end
            
            
            TimesVec=obj.Resolution*[1:obj.HISTCHAN]/1000; %Vector of times in nanoseconds
            hist=countsbuffer;
        end
        
        
        function IsDone=CheckAquisitionDone(obj)
             %This function checks if the acquisition is done
             ctcdone = int32(0);
             ctcdonePtr = libpointer('int32Ptr', ctcdone);
             [ret, IsDone] = calllib(obj.LibName, 'PH_CTCStatus', obj.DevIdx, ctcdonePtr);
        end
        
    end
    
end



