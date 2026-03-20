classdef TTTimeTaggerSource < handle
    properties (Access = private)
        timeTaggerSource
    end
    methods (Access = public)
        function obj = TTTimeTaggerSource(dotNET_object)
            obj.timeTaggerSource = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerSource)
                obj.timeTaggerSource.Dispose();
                obj.timeTaggerSource = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerSource;
        end
        function setInputDelay(obj, channel, delay)
            obj.timeTaggerSource.setInputDelay(channel, delay);
        end
        function ret = getInputDelay(obj, channel)
            ret = int64(obj.timeTaggerSource.getInputDelay(channel));
        end
        function setDelayHardware(obj, channel, delay)
            obj.timeTaggerSource.setDelayHardware(channel, delay);
        end
        function ret = getDelayHardware(obj, channel)
            ret = int64(obj.timeTaggerSource.getDelayHardware(channel));
        end
        function ret = getDelayHardwareRange(obj, channel)
            ret = int64(obj.timeTaggerSource.getDelayHardwareRange(channel));
        end
        function setDelaySoftware(obj, channel, delay)
            obj.timeTaggerSource.setDelaySoftware(channel, delay);
        end
        function ret = getDelaySoftware(obj, channel)
            ret = int64(obj.timeTaggerSource.getDelaySoftware(channel));
        end
        function ret = setDeadtime(obj, channel, deadtime)
            ret = int64(obj.timeTaggerSource.setDeadtime(channel, deadtime));
        end
        function ret = getDeadtime(obj, channel)
            ret = int64(obj.timeTaggerSource.getDeadtime(channel));
        end
        function ret = getDeadtimeRange(obj, channel)
            ret = int64(obj.timeTaggerSource.getDeadtimeRange(channel));
        end
        function setConditionalFilter(obj, trigger, filtered)
            obj.timeTaggerSource.setConditionalFilter(trigger, filtered);
        end
        function clearConditionalFilter(obj)
            obj.timeTaggerSource.clearConditionalFilter();
        end
        function ret = getConditionalFilterTrigger(obj)
            ret = int32(obj.timeTaggerSource.getConditionalFilterTrigger());
        end
        function ret = getConditionalFilterFiltered(obj)
            ret = int32(obj.timeTaggerSource.getConditionalFilterFiltered());
        end
        function setEventDivider(obj, channel, divider)
            obj.timeTaggerSource.setEventDivider(channel, divider);
        end
        function ret = getEventDivider(obj, channel)
            ret = uint32(obj.timeTaggerSource.getEventDivider(channel));
        end
        function ret = getOverflows(obj)
            ret = int64(obj.timeTaggerSource.getOverflows());
        end
        function ret = getOverflowsAndClear(obj)
            ret = int64(obj.timeTaggerSource.getOverflowsAndClear());
        end
        function clearOverflows(obj)
            obj.timeTaggerSource.clearOverflows();
        end
        function setReferenceClock(obj, clock_channel, clock_frequency, time_constant, synchronization_channel, synchronization_offset, wait_until_locked)
            narginchk(2, 7);
            if nargin == 2
                obj.timeTaggerSource.setReferenceClock(clock_channel);
            end
            if nargin == 3
                obj.timeTaggerSource.setReferenceClock(clock_channel, clock_frequency);
            end
            if nargin == 4
                obj.timeTaggerSource.setReferenceClock(clock_channel, clock_frequency, time_constant);
            end
            if nargin == 5
                obj.timeTaggerSource.setReferenceClock(clock_channel, clock_frequency, time_constant, synchronization_channel);
            end
            if nargin == 6
                obj.timeTaggerSource.setReferenceClock(clock_channel, clock_frequency, time_constant, synchronization_channel, synchronization_offset);
            end
            if nargin == 7
                obj.timeTaggerSource.setReferenceClock(clock_channel, clock_frequency, time_constant, synchronization_channel, synchronization_offset, wait_until_locked);
            end
        end
        function disableReferenceClock(obj)
            obj.timeTaggerSource.disableReferenceClock();
        end
        function ret = getReferenceClockState(obj)
            ret = TTReferenceClockState(obj.timeTaggerSource.getReferenceClockState());
        end
    end
end