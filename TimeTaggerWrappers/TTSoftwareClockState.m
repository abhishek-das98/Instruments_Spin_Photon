classdef TTSoftwareClockState < handle
    properties (Access = private)
        softwareClockState
    end
    properties (Access = public)
        clock_period
        input_channel
        ideal_clock_channel
        averaging_periods
        enabled
        is_locked
        error_counter
        last_ideal_clock_event
        period_error
        phase_error_estimation
    end
    methods (Access = public)
        function obj = TTSoftwareClockState(dotNET_object)
            obj.softwareClockState = dotNET_object;
            obj.clock_period = int64(dotNET_object.clock_period);
            obj.input_channel = int32(dotNET_object.input_channel);
            obj.ideal_clock_channel = int32(dotNET_object.ideal_clock_channel);
            obj.averaging_periods = double(dotNET_object.averaging_periods);
            obj.enabled = logical(dotNET_object.enabled);
            obj.is_locked = logical(dotNET_object.is_locked);
            obj.error_counter = uint32(dotNET_object.error_counter);
            obj.last_ideal_clock_event = int64(dotNET_object.last_ideal_clock_event);
            obj.period_error = double(dotNET_object.period_error);
            obj.phase_error_estimation = double(dotNET_object.phase_error_estimation);
        end
        function delete(obj)
            if ~isempty(obj.softwareClockState)
                obj.softwareClockState.Dispose();
                obj.softwareClockState = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.softwareClockState;
        end
    end
end