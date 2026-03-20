classdef TTTimeTagStreamBuffer < handle
    properties (Access = private)
        timeTagStreamBuffer
    end
    properties (Access = public)
        size
        hasOverflows
        tStart
        tGetData
    end
    methods (Access = public)
        function obj = TTTimeTagStreamBuffer(dotNET_object)
            obj.timeTagStreamBuffer = dotNET_object;
            obj.size = uint64(dotNET_object.size);
            obj.hasOverflows = logical(dotNET_object.hasOverflows);
            obj.tStart = int64(dotNET_object.tStart);
            obj.tGetData = int64(dotNET_object.tGetData);
        end
        function delete(obj)
            if ~isempty(obj.timeTagStreamBuffer)
                obj.timeTagStreamBuffer.Dispose();
                obj.timeTagStreamBuffer = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTagStreamBuffer;
        end
        function ret = getTimestamps(obj)
            ret = int64(obj.timeTagStreamBuffer.getTimestamps());
        end
        function ret = getChannels(obj)
            ret = int32(obj.timeTagStreamBuffer.getChannels());
        end
        function ret = getOverflows(obj)
            ret = uint8(obj.timeTagStreamBuffer.getOverflows());
        end
        function ret = getEventTypes(obj)
            ret = uint8(obj.timeTagStreamBuffer.getEventTypes());
        end
        function ret = getMissedEvents(obj)
            ret = uint16(obj.timeTagStreamBuffer.getMissedEvents());
        end
    end
end