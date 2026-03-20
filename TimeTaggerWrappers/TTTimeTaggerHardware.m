classdef TTTimeTaggerHardware < handle
    properties (Access = private)
        timeTaggerHardware
    end
    methods (Access = public)
        function obj = TTTimeTaggerHardware(dotNET_object)
            obj.timeTaggerHardware = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerHardware)
                obj.timeTaggerHardware.Dispose();
                obj.timeTaggerHardware = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerHardware;
        end
        function setTriggerLevel(obj, channel, voltage)
            obj.timeTaggerHardware.setTriggerLevel(channel, voltage);
        end
        function ret = getTriggerLevel(obj, channel)
            ret = double(obj.timeTaggerHardware.getTriggerLevel(channel));
        end
        function ret = getHardwareDelayCompensation(obj, channel)
            ret = int64(obj.timeTaggerHardware.getHardwareDelayCompensation(channel));
        end
        function setHardwareDelayCompensationActive(obj, use_compensation)
            obj.timeTaggerHardware.setHardwareDelayCompensationActive(use_compensation);
        end
        function setInputImpedanceHigh(obj, channel, high_impedance)
            obj.timeTaggerHardware.setInputImpedanceHigh(channel, high_impedance);
        end
        function ret = getInputImpedanceHigh(obj, channel)
            ret = logical(obj.timeTaggerHardware.getInputImpedanceHigh(channel));
        end
        function setInputHysteresis(obj, channel, value)
            obj.timeTaggerHardware.setInputHysteresis(channel, value);
        end
        function ret = getInputHysteresis(obj, channel)
            ret = int32(obj.timeTaggerHardware.getInputHysteresis(channel));
        end
        function setNormalization(obj, channels, state)
            obj.timeTaggerHardware.setNormalization(channels, state);
        end
        function ret = getNormalization(obj, channel)
            ret = logical(obj.timeTaggerHardware.getNormalization(channel));
        end
        function ret = getSerial(obj)
            ret = char(obj.timeTaggerHardware.getSerial());
        end
        function ret = getModel(obj)
            ret = char(obj.timeTaggerHardware.getModel());
        end
        function ret = getPcbVersion(obj)
            ret = char(obj.timeTaggerHardware.getPcbVersion());
        end
        function ret = getFirmwareVersion(obj)
            ret = char(obj.timeTaggerHardware.getFirmwareVersion());
        end
        function ret = getDACRange(obj)
            ret = double(obj.timeTaggerHardware.getDACRange());
        end
        function ret = getTriggerLevelRange(obj, channel)
            ret = double(obj.timeTaggerHardware.getTriggerLevelRange(channel));
        end
        function ret = getChannelList(obj, type)
            narginchk(1, 2);
            if nargin == 1
                ret = int32(obj.timeTaggerHardware.getChannelList());
            end
            if nargin == 2
                type = SwabianInstruments.TimeTagger.ChannelEdge.(char(type));
                ret = int32(obj.timeTaggerHardware.getChannelList(type));
            end
        end
        function setHardwareBufferSize(obj, size)
            obj.timeTaggerHardware.setHardwareBufferSize(size);
        end
        function ret = getHardwareBufferSize(obj)
            ret = int32(obj.timeTaggerHardware.getHardwareBufferSize());
        end
        function ret = getPsPerClock(obj)
            ret = int64(obj.timeTaggerHardware.getPsPerClock());
        end
        function setStreamBlockSize(obj, max_events, max_latency)
            obj.timeTaggerHardware.setStreamBlockSize(max_events, max_latency);
        end
        function ret = getStreamBlockSizeEvents(obj)
            ret = int32(obj.timeTaggerHardware.getStreamBlockSizeEvents());
        end
        function ret = getStreamBlockSizeLatency(obj)
            ret = int32(obj.timeTaggerHardware.getStreamBlockSizeLatency());
        end
        function setTestSignal(obj, channel, enabled)
            obj.timeTaggerHardware.setTestSignal(channel, enabled);
        end
        function ret = getTestSignal(obj, channel)
            ret = logical(obj.timeTaggerHardware.getTestSignal(channel));
        end
        function setTestSignalDivider(obj, divider)
            obj.timeTaggerHardware.setTestSignalDivider(divider);
        end
        function ret = getTestSignalDivider(obj)
            ret = int32(obj.timeTaggerHardware.getTestSignalDivider());
        end
        function ret = getDeviceLicense(obj)
            ret = char(obj.timeTaggerHardware.getDeviceLicense());
        end
        function ret = getSensorData(obj)
            ret = char(obj.timeTaggerHardware.getSensorData());
        end
        function disableLEDs(obj, disabled)
            obj.timeTaggerHardware.disableLEDs(disabled);
        end
        function setLED(obj, bitmask)
            obj.timeTaggerHardware.setLED(bitmask);
        end
        function setSoundFrequency(obj, freq_hz)
            obj.timeTaggerHardware.setSoundFrequency(freq_hz);
        end
        function setTimeTaggerNetworkStreamCompression(obj, active)
            obj.timeTaggerHardware.setTimeTaggerNetworkStreamCompression(active);
        end
        function ret = getChannelNumberScheme(obj)
            ret = int32(obj.timeTaggerHardware.getChannelNumberScheme());
        end
    end
end