classdef TTReferenceClockState < handle
    properties (Access = private)
        referenceClockState
    end
    properties (Access = public)
        clock_period
        clock_channel
        synchronization_channel
        ideal_clock_channel
        averaging_periods
        synchronization_offset
        enabled
        event_divider
        is_locked
        is_synchronized
        error_counter
        last_ideal_clock_event
        period_error
        phase_error_estimation
    end
    methods (Access = public)
        function obj = TTReferenceClockState(dotNET_object)
            obj.referenceClockState = dotNET_object;
            obj.clock_period = int64(dotNET_object.clock_period);
            obj.clock_channel = int32(dotNET_object.clock_channel);
            obj.synchronization_channel = int32(dotNET_object.synchronization_channel);
            obj.ideal_clock_channel = int32(dotNET_object.ideal_clock_channel);
            obj.averaging_periods = double(dotNET_object.averaging_periods);
            obj.synchronization_offset = int64(dotNET_object.synchronization_offset);
            obj.enabled = logical(dotNET_object.enabled);
            obj.event_divider = int32(dotNET_object.event_divider);
            obj.is_locked = logical(dotNET_object.is_locked);
            obj.is_synchronized = logical(dotNET_object.is_synchronized);
            obj.error_counter = uint32(dotNET_object.error_counter);
            obj.last_ideal_clock_event = int64(dotNET_object.last_ideal_clock_event);
            obj.period_error = double(dotNET_object.period_error);
            obj.phase_error_estimation = double(dotNET_object.phase_error_estimation);
        end
        function delete(obj)
            if ~isempty(obj.referenceClockState)
                obj.referenceClockState.Dispose();
                obj.referenceClockState = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.referenceClockState;
        end
    end
end