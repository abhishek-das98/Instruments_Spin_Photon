classdef TTEvent < handle
    properties (Access = private)
        event
    end
    properties (Access = public)
        time
        state
    end
    methods (Access = public)
        function obj = TTEvent(dotNET_object)
            obj.event = dotNET_object;
            obj.time = int64(dotNET_object.time);
            obj.state = TTState(int32(dotNET_object.state));
        end
        function delete(obj)
            if ~isempty(obj.event)
                obj.event.Dispose();
                obj.event = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.event;
        end
    end
end