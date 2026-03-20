classdef TTCounterData < handle
    properties (Access = private)
        counterData
    end
    properties (Access = public)
        size
        dropped_bins
        overflow
    end
    methods (Access = public)
        function obj = TTCounterData(dotNET_object)
            obj.counterData = dotNET_object;
            obj.size = uint32(dotNET_object.size);
            obj.dropped_bins = uint32(dotNET_object.dropped_bins);
            obj.overflow = logical(dotNET_object.overflow);
        end
        function delete(obj)
            if ~isempty(obj.counterData)
                obj.counterData.Dispose();
                obj.counterData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.counterData;
        end
        function ret = getIndex(obj)
            ret = int64(obj.counterData.getIndex());
        end
        function ret = getData(obj)
            ret = int32(obj.counterData.getData());
        end
        function ret = getDataNormalized(obj)
            ret = double(obj.counterData.getDataNormalized());
        end
        function ret = getFrequency(obj, time_scale)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.counterData.getFrequency());
            end
            if nargin == 2
                ret = double(obj.counterData.getFrequency(time_scale));
            end
        end
        function ret = getDataTotalCounts(obj)
            ret = uint64(obj.counterData.getDataTotalCounts());
        end
        function ret = getTime(obj)
            ret = int64(obj.counterData.getTime());
        end
        function ret = getOverflowMask(obj)
            ret = int8(obj.counterData.getOverflowMask());
        end
        function ret = getChannels(obj)
            ret = int32(obj.counterData.getChannels());
        end
    end
end