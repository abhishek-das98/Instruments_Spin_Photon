classdef TimeTagger < TTTimeTaggerBase & TTTimeTaggerHardware
    properties (Access = private)
        timeTagger
    end
    properties (Constant, Access = public)
        CHANNEL_UNUSED = int32(-134217728);
        WRAPPER_BACKEND_VERSION = '2.20.0';
    end
    methods (Static, Access = public)
        function loadAssembly()
            persistent TimeTaggerAssemblyLoaded
            if isempty(TimeTaggerAssemblyLoaded)
                TimeTaggerAssemblyLoaded = false;
            end
            if ~TimeTaggerAssemblyLoaded
                NET.addAssembly('SwabianInstruments.TimeTagger');
                dllBackendVersion = char(SwabianInstruments.TimeTagger.TT.getVersion());
                if ~strcmp(TimeTagger.WRAPPER_BACKEND_VERSION, dllBackendVersion)
                    error('Matlab wrapper version "%s" inconsistent with Time Tagger version "%s". \nPlease update the TimeTagger software to the latest version by visiting <a href="https://www.swabianinstruments.com/time-tagger/downloads/">the TimeTagger downloads page</a>.', TimeTagger.WRAPPER_BACKEND_VERSION, dllBackendVersion)
                end
                TimeTaggerAssemblyLoaded = true;
                SwabianInstruments.TimeTagger.TT.setLanguageInfo(2128365692, SwabianInstruments.TimeTagger.LanguageUsed.Matlab, version);
                TimeTagger.setLogger(@TTDefaultLogger)
            end
        end
    end
    methods (Static)
        function setLogger(logger)
            TimeTagger.loadAssembly();
            if ~isa(logger,'function_handle')
                error(strcat('The argument passed to setLogger must be a function handle!'));
            end
            try
                if (nargin(logger) ~= 2)
                    throw(MException('TimeTagger', 'setLogger wrong number of arguments'));
                end
            catch
                error(strcat('Log handler "', func2str(logger), '" does not exist or does not have the required number of arguments'));
            end
            SwabianInstruments.TimeTagger.TT.setLogger(logger);
        end
        function removeAllLogger()
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.removeAllLogger();
        end
        function ret = hasLogger()
            TimeTagger.loadAssembly();
            ret = logical(SwabianInstruments.TimeTagger.TT.hasLogger());
        end
        function ret = getVersion()
            TimeTagger.loadAssembly();
            ret = char(SwabianInstruments.TimeTagger.TT.getVersion());
        end
        function ret = getCompilerVersion()
            TimeTagger.loadAssembly();
            ret = char(SwabianInstruments.TimeTagger.TT.getCompilerVersion());
        end
        function ret = getCompilationTimestamp()
            TimeTagger.loadAssembly();
            ret = int64(SwabianInstruments.TimeTagger.TT.getCompilationTimestamp());
        end
        function ret = createTimeTagger(serial, resolution)
            TimeTagger.loadAssembly();
            narginchk(0, 2);
            if nargin == 0
                ret = TimeTagger(SwabianInstruments.TimeTagger.TT.createTimeTagger());
            end
            if nargin == 1
                ret = TimeTagger(SwabianInstruments.TimeTagger.TT.createTimeTagger(serial));
            end
            if nargin == 2
                resolution = SwabianInstruments.TimeTagger.Resolution.(char(resolution));
                ret = TimeTagger(SwabianInstruments.TimeTagger.TT.createTimeTagger(serial, resolution));
            end
        end
        function ret = createTimeTaggerVirtual(filename, begin, duration)
            TimeTagger.loadAssembly();
            narginchk(0, 3);
            if nargin == 0
                ret = TimeTaggerVirtual(SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual());
            end
            if nargin == 1
                ret = TimeTaggerVirtual(SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename));
            end
            if nargin == 2
                ret = TimeTaggerVirtual(SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename, begin));
            end
            if nargin == 3
                ret = TimeTaggerVirtual(SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename, begin, duration));
            end
        end
        function ret = createTimeTaggerNetwork(address)
            TimeTagger.loadAssembly();
            narginchk(0, 1);
            if nargin == 0
                ret = TimeTaggerNetwork(SwabianInstruments.TimeTagger.TT.createTimeTaggerNetwork());
            end
            if nargin == 1
                ret = TimeTaggerNetwork(SwabianInstruments.TimeTagger.TT.createTimeTaggerNetwork(address));
            end
        end
        function setCustomBitFileName(bitFileName)
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.setCustomBitFileName(bitFileName);
        end
        function ret = scanTimeTagger(include_model_name)
            TimeTagger.loadAssembly();
            narginchk(0, 1);
            if nargin == 0
                ret = cell(SwabianInstruments.TimeTagger.TT.scanTimeTagger());
            end
            if nargin == 1
                ret = cell(SwabianInstruments.TimeTagger.TT.scanTimeTagger(include_model_name));
            end
        end
        function ret = getTimeTaggerServerInfo(address)
            TimeTagger.loadAssembly();
            narginchk(0, 1);
            if nargin == 0
                ret = char(SwabianInstruments.TimeTagger.TT.getTimeTaggerServerInfo());
            end
            if nargin == 1
                ret = char(SwabianInstruments.TimeTagger.TT.getTimeTaggerServerInfo(address));
            end
        end
        function ret = scanTimeTaggerServers()
            TimeTagger.loadAssembly();
            ret = cell(SwabianInstruments.TimeTagger.TT.scanTimeTaggerServers());
        end
        function ret = getTimeTaggerModel(serial)
            TimeTagger.loadAssembly();
            ret = char(SwabianInstruments.TimeTagger.TT.getTimeTaggerModel(serial));
        end
        function setTimeTaggerChannelNumberScheme(scheme)
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.setTimeTaggerChannelNumberScheme(scheme);
        end
        function ret = getTimeTaggerChannelNumberScheme()
            TimeTagger.loadAssembly();
            ret = int32(SwabianInstruments.TimeTagger.TT.getTimeTaggerChannelNumberScheme());
        end
        function ret = hasTimeTaggerVirtualLicense()
            TimeTagger.loadAssembly();
            ret = logical(SwabianInstruments.TimeTagger.TT.hasTimeTaggerVirtualLicense());
        end
        function flashLicense(serial, license)
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.flashLicense(serial, license);
        end
        function ret = extractDeviceLicense(license)
            TimeTagger.loadAssembly();
            ret = char(SwabianInstruments.TimeTagger.TT.extractDeviceLicense(license));
        end
        function checkSystemLibraries()
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.checkSystemLibraries();
        end
        function setFrontend(frontend)
            TimeTagger.loadAssembly();
            frontend = SwabianInstruments.TimeTagger.FrontendType.(char(frontend));
            SwabianInstruments.TimeTagger.TT.setFrontend(frontend);
        end
        function setUsageStatisticsStatus(new_status)
            TimeTagger.loadAssembly();
            new_status = SwabianInstruments.TimeTagger.UsageStatisticsStatus.(char(new_status));
            SwabianInstruments.TimeTagger.TT.setUsageStatisticsStatus(new_status);
        end
        function ret = getUsageStatisticsStatus()
            TimeTagger.loadAssembly();
            ret = TTUsageStatisticsStatus(SwabianInstruments.TimeTagger.TT.getUsageStatisticsStatus());
        end
        function ret = getUsageStatisticsReport()
            TimeTagger.loadAssembly();
            ret = char(SwabianInstruments.TimeTagger.TT.getUsageStatisticsReport());
        end
        function mergeStreamFiles(output_filename, input_filenames, channel_offsets, time_offsets, overlap_only)
            TimeTagger.loadAssembly();
            SwabianInstruments.TimeTagger.TT.mergeStreamFiles(output_filename, input_filenames, channel_offsets, time_offsets, overlap_only);
        end
    end
    methods (Access = public)
        function obj = TimeTagger(serial, resolution)
            TimeTagger.loadAssembly();
            if nargin == 1 && isa(serial, 'SwabianInstruments.TimeTagger.TimeTaggerBase')
                tt = serial; else
                warning(['directly calling the TimeTagger class to instantiate a Time Tagger is deprecated !' ...
                    '\n%s To create an instance of TimeTagger, please call TimeTagger.createTimeTagger() instead.'], '')
                narginchk(0, 2);
                if nargin == 0
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTagger();
                end
                if nargin == 1
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTagger(serial);
                end
                if nargin == 2
                    resolution = SwabianInstruments.TimeTagger.Resolution.(char(resolution));
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTagger(serial, resolution);
                end
            end
            obj@TTTimeTaggerBase(tt);
            obj@TTTimeTaggerHardware(tt);
            obj.timeTagger = tt;
        end
        function delete(obj)
            if ~isempty(obj.timeTagger)
                obj.timeTagger.Dispose();
                obj.timeTagger = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTagger;
        end
        function freeTimeTagger(obj)
            if ~isempty(obj.timeTagger)
                obj.timeTagger.Dispose();
                obj.timeTagger = [];
            end
        end
        function reset(obj)
            obj.timeTagger.reset();
        end
        function ret = autoCalibration(obj)
            ret = double(obj.timeTagger.autoCalibration());
        end
        function enableFpgaLink(obj, channels, destination_mac, link_interface, exclusive)
            narginchk(3, 5);
            if nargin == 3
                obj.timeTagger.enableFpgaLink(channels, destination_mac);
            end
            if nargin == 4
                link_interface = SwabianInstruments.TimeTagger.FpgaLinkInterface.(char(link_interface));
                obj.timeTagger.enableFpgaLink(channels, destination_mac, link_interface);
            end
            if nargin == 5
                link_interface = SwabianInstruments.TimeTagger.FpgaLinkInterface.(char(link_interface));
                obj.timeTagger.enableFpgaLink(channels, destination_mac, link_interface, exclusive);
            end
        end
        function disableFpgaLink(obj)
            obj.timeTagger.disableFpgaLink();
        end
        function startServer(obj, access_mode, channels, port)
            narginchk(2, 4);
            access_mode = SwabianInstruments.TimeTagger.AccessMode.(char(access_mode));
            if nargin == 2
                obj.timeTagger.startServer(access_mode);
            end
            if nargin == 3
                obj.timeTagger.startServer(access_mode, channels);
            end
            if nargin == 4
                obj.timeTagger.startServer(access_mode, channels, port);
            end
        end
        function stopServer(obj)
            obj.timeTagger.stopServer();
        end
        function ret = isServerRunning(obj)
            ret = logical(obj.timeTagger.isServerRunning());
        end
        function setServerAddress(obj, ip_address)
            obj.timeTagger.setServerAddress(ip_address);
        end
        function ret = getServerAddress(obj)
            ret = char(obj.timeTagger.getServerAddress());
        end
        function ret = getConnectedClients(obj)
            ret = cell(obj.timeTagger.getConnectedClients());
        end
        function xtra_setAvgRisingFalling(obj, channel, enable)
            obj.timeTagger.xtra_setAvgRisingFalling(channel, enable);
        end
        function ret = xtra_getAvgRisingFalling(obj, channel)
            ret = logical(obj.timeTagger.xtra_getAvgRisingFalling(channel));
        end
        function xtra_setHighPrioChannel(obj, channel, enable)
            obj.timeTagger.xtra_setHighPrioChannel(channel, enable);
        end
        function ret = xtra_getHighPrioChannel(obj, channel)
            ret = logical(obj.timeTagger.xtra_getHighPrioChannel(channel));
        end
        function xtra_setAuxOut(obj, channel, enabled)
            obj.timeTagger.xtra_setAuxOut(channel, enabled);
        end
        function ret = xtra_getAuxOut(obj, channel)
            ret = logical(obj.timeTagger.xtra_getAuxOut(channel));
        end
        function xtra_setAuxOutSignal(obj, channel, divider, duty_cycle)
            narginchk(3, 4);
            if nargin == 3
                obj.timeTagger.xtra_setAuxOutSignal(channel, divider);
            end
            if nargin == 4
                obj.timeTagger.xtra_setAuxOutSignal(channel, divider, duty_cycle);
            end
        end
        function ret = xtra_getAuxOutSignalDivider(obj, channel)
            ret = int32(obj.timeTagger.xtra_getAuxOutSignalDivider(channel));
        end
        function ret = xtra_getAuxOutSignalDutyCycle(obj, channel)
            ret = double(obj.timeTagger.xtra_getAuxOutSignalDutyCycle(channel));
        end
        function ret = xtra_measureTriggerLevel(obj, channel)
            ret = double(obj.timeTagger.xtra_measureTriggerLevel(channel));
        end
        function xtra_setClockSource(obj, source)
            obj.timeTagger.xtra_setClockSource(source);
        end
        function ret = xtra_getClockSource(obj)
            ret = int32(obj.timeTagger.xtra_getClockSource());
        end
        function xtra_setClockAutoSelect(obj, enabled)
            obj.timeTagger.xtra_setClockAutoSelect(enabled);
        end
        function ret = xtra_getClockAutoSelect(obj)
            ret = logical(obj.timeTagger.xtra_getClockAutoSelect());
        end
        function xtra_setClockOut(obj, enabled)
            obj.timeTagger.xtra_setClockOut(enabled);
        end
        function xtra_setFanSpeed(obj, percentage)
            narginchk(1, 2);
            if nargin == 1
                obj.timeTagger.xtra_setFanSpeed();
            end
            if nargin == 2
                obj.timeTagger.xtra_setFanSpeed(percentage);
            end
        end
        function setInputMux(obj, channel, mux_mode)
            obj.timeTagger.setInputMux(channel, mux_mode);
        end
        function ret = getInputMux(obj, channel)
            ret = int32(obj.timeTagger.getInputMux(channel));
        end
        function updateBMCFirmware(obj, firmware)
            obj.timeTagger.updateBMCFirmware(firmware);
        end
    end
end