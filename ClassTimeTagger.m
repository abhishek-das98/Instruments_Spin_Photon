% The Spin Photon Lab - North Carolina State University
% This class is for handling MATLAB use of the Swabian TimeTagger
% Before using this class we need to make sure the software of
% the tool has been installed (the host computer should be online when installing)
% In this case the library and handling DLL will automatically be insttaled
% as a MATLAB toolbox on the host MATLAB.
% This class is just for one TimeTagger, therfore, in case of using multiple
% it needs to be modified in order to be able to use this code on MATLAB,
% the device should not be connected through other software platforms

classdef (Sealed) ClassTimeTagger < handle % cannot be inherited

    properties (Dependent = true)
        % Picoharp-style settings kept for compatibility
        ZeroCr0
        ZeroDiscr0
        ZeroDivider0
        Offset0
        ZeroOffset0
        ZeroCr1
        ZeroDiscr1
        Resolution
        Block % Kept for compatibility with the TCSPC-style interface
        Mode
        Offset
        TimeStop
        CountStop
    end

    properties (Access = private)
        tagger % Instance of the TimeTagger object
        histogramObj
        DevIdx = 0
        TimeStopPrivate = 360000
        ResolutionPrivate = 4
        BaseResolution = 4
        NumBinsPrivate = 1000
        overflow % Instance of the overflow
        softwareClock % software clock
        binwidth = 1e9 % (int) - bin width in ps (default: 1e9)
        nValues = 1 % (int) - number of bins (default: 1)
        SyncChannelNumber = 1; %channel number of sync signal is 0
        defaultChannel = 1
        ZeroDiscr0Private = -0.25
        ZeroDiscr1Private = -0.11
        clear = true
        CLICK_CHANNEL = 2
        START_CHANNEL = 1
    end

    methods
        function TimeStop = get.TimeStop(obj)
            TimeStop = obj.TimeStopPrivate;
        end

        function Resolution = get.Resolution(obj)
            Resolution = obj.ResolutionPrivate;
        end
    end

    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassTimeTagger;
            end
            obj = localObj;
        end
    end

    methods (Static, Access = private)
        function EnsureWrapperPath()
            classFolder = fileparts(mfilename('fullpath'));
            wrapperFolder = fullfile(classFolder, 'TimeTaggerWrappers');

            if ~exist(wrapperFolder, 'dir')
                error('TimeTagger wrapper folder not found: %s', wrapperFolder);
            end

            if isempty(strfind(path, wrapperFolder))
                addpath(wrapperFolder);
            end
        end
    end
    
    methods
        function CloseConnection(obj)
            fprintf('\nclosing all Swabian devices\n');

            % Method to destroy the TimeTagger instance
            if ~isempty(obj.tagger)
                freeTimeTagger(obj.tagger);
                delete(obj.tagger); % Destroy the TimeTagger instance
                obj.tagger = []; % Clear the reference
                disp('TimeTagger instance destroyed.');
            else
                disp('No active TimeTagger instance to destroy.');
            end
        end

        function SetParams(obj)
            % Binning 0 -> Resolution = base, Binning 1 -> Resolution = 2^1*base, etc.
            Binning = log2(obj.Resolution ./ obj.BaseResolution);
            [ret] = calllib(obj.LibName, 'PH_SetBinning', obj.DevIdx, Binning);
            obj.CheckError('\nPH_SetBinning error', ret);

            [ret] = calllib(obj.LibName, 'PH_SetOffset', obj.DevIdx, obj.Offset);
            obj.CheckError('\nPH_SetOffset error', ret);

            ret = calllib(obj.LibName, 'PH_SetStopOverflow', obj.DevIdx, 1, obj.CountStop);
            obj.CheckError('\nPH_SetStopOverflow error', ret);

            ResolutionFromDevice = 0;
            ResolutionPtr = libpointer('doublePtr', ResolutionFromDevice);
            [ret, ResolutionFromDevice] = calllib(obj.LibName, 'PH_GetResolution', obj.DevIdx, ResolutionPtr);
            obj.CheckError('\nPH_GetResolution error', ret);
            if (ResolutionFromDevice ~= obj.Resolution)
                % Check if the resolution read from the device matches the requested one.
                error('Resolution setting error. Aborted.\n');
            end

            % Note: after Init or SetSyncDiv you must allow 100 ms for valid new count rate readings
            pause(0.2);

            % Save the acquisition settings in a file with a name corresponding to the block number.
            filename = ['SettingsChannel' num2str(obj.Block) '.out'];
            fid = fopen(filename, 'w');
            obj.CheckError('Cannot open output file', ret);

            fprintf(fid, 'Binning          : %ld\n', Binning);
            fprintf(fid, 'Resolution          : %ld\n', ResolutionFromDevice);
            fprintf(fid, 'Offset           : %ld\n', obj.Offset);
            fprintf(fid, 'AcquisitionTime  : %ld\n', obj.TimeStop);
            fprintf(fid, 'SyncDivider      : %ld\n', obj.ZeroDivider0);
            fprintf(fid, 'SyncOffset       : %ld\n', obj.ZeroOffset0);
            fprintf(fid, 'CFDZeroCross0    : %ld\n', obj.ZeroCr0);
            fprintf(fid, 'CFDLevel0        : %ld\n', obj.ZeroDiscr0);
            fprintf(fid, 'CFDZeroCross1    : %ld\n', obj.ZeroCr1);
            fprintf(fid, 'CFDLevel1        : %ld\n', obj.ZeroDiscr1);
            fclose(fid);
        end

        function SetTimeStop(obj, T)
            obj.TimeStopPrivate = T;
        end
        function SetTriggerLevels(obj, C, V)
            obj.tagger.setTriggerLevel(C, V);
        end
        function SetChannels(obj, startChannel, clickChannel)
            obj.START_CHANNEL = startChannel;
            obj.CLICK_CHANNEL = clickChannel;
            obj.SyncChannelNumber = startChannel;
        end
        function SetNumBins(obj, B)
            obj.NumBinsPrivate = B;
        end
        function SetResolution(obj, R)
            obj.ResolutionPrivate = R;
        end

        function connect(obj) 
            % Create a TimeTagger instance.
            ClassTimeTagger.EnsureWrapperPath();
            obj.tagger = TimeTagger.createTimeTagger();
        end

        function getOverflows(obj)
            obj.overflow = obj.tagger.getOverflows();
        end

        function setSoftwareClock(obj)
            obj.softwareClock = obj.tagger.setSoftwareClock();
        end

        function count = ReadCounter(obj, channel)
            counter = TTCountrate(obj.tagger, channel);
            while isnan(counter.getData())
            end
            count = round(counter.getData());
        end

        function rate = GetSyncRate(obj)
            % gets the rate of the sync signal in MHz
            rate = obj.ReadCounter(obj.SyncChannelNumber);
        end

        function StopAcquisition(obj)
            % This function stops acquiring a histogram
            obj.histogramObj.stop();
        end

        function ResumeAcquisition(obj, T)
            obj.histogramObj.startFor(round(T * 1e12));
        end

        function StartAcquisition(obj)
            % This function starts acquiring a histogram
            % update all the recent swabian parameters required for the acquisition

            %obj.SetParams();
            obj.histogramObj = TTHistogram(obj.tagger, obj.CLICK_CHANNEL, obj.START_CHANNEL, obj.ResolutionPrivate, obj.NumBinsPrivate);
            pause(0.5);
            % Clear histogram memory
            obj.histogramObj.clear();

            % Start acquisition
            obj.ResumeAcquisition(obj.TimeStop);

            fprintf('Measuring for %1d seconds\n', obj.TimeStop);
        end

        function [TimesVec, hist] = GetHistogram(obj)

            % MAS TODO: should take care of free run stuff

            % This function returns the data histogram versus time in nanoseconds.
            % classHistogram(tagger, click_channel[, start_channel=CHANNEL_UNUSED, binwidth=1000, n_bins=1000])
            %     Parameters:
            %     tagger (TimeTaggerBase) - time tagger object instance
            %     click_channel (int) - channel on which clicks are received
            %     start_channel (int) - channel on which start clicks are received (default: CHANNEL_UNUSED)
            %     binwidth (int) - bin width in ps (default: 1000)
            %     n_bins (int) - the number of bins in the histogram (default: 1000)
            %     See all common methods
            %     getData()
            %     Returns: A one-dimensional array of size n_bins containing the histogram.
            %     Return type: 1D_array[int]
            %     getIndex()
            %     Returns: A vector of size n_bins containing the time bins in ps.
            %     Return type: 1D_array[int]

            % countsbuffer  = uint32(zeros(1,obj.HISTCHAN));
            % bufferptr = libpointer('uint32Ptr', countsbuffer);
            % MAS TODO: Do we need this line?
            countsbuffer = obj.histogramObj.getData;

            % MAS TODO: overflow shoule be taken care of in terms of
            % Swabian

            % TimesVec=obj.Resolution*[1:obj.HISTCHAN]/1000; %Vector of times in nanoseconds
            % MAS TODO: prev line needs to be taken care of
            TimesVec = double(obj.histogramObj.getIndex) / 1000;
            hist = countsbuffer;
        end

        function IsDone = CheckAquisitionDone(obj)
            % This function checks if the acquisition is done
            if isempty(obj.histogramObj)
                IsDone = true;
            else
                IsDone = ~obj.histogramObj.isRunning();
            end
        end
    end
end
