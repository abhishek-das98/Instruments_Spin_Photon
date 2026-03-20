classdef TTHistogramLogBinsData < handle
    properties (Access = private)
        histogramLogBinsData
    end
    properties (Access = public)
        accumulation_time_start
        accumulation_time_click
    end
    methods (Access = public)
        function obj = TTHistogramLogBinsData(dotNET_object)
            obj.histogramLogBinsData = dotNET_object;
            obj.accumulation_time_start = int64(dotNET_object.accumulation_time_start);
            obj.accumulation_time_click = int64(dotNET_object.accumulation_time_click);
        end
        function delete(obj)
            if ~isempty(obj.histogramLogBinsData)
                obj.histogramLogBinsData.Dispose();
                obj.histogramLogBinsData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogramLogBinsData;
        end
        function ret = getG2(obj)
            ret = double(obj.histogramLogBinsData.getG2());
        end
        function ret = getCounts(obj)
            ret = uint64(obj.histogramLogBinsData.getCounts());
        end
        function ret = getG2Normalization(obj)
            ret = double(obj.histogramLogBinsData.getG2Normalization());
        end
    end
end