classdef TTCorrelationPairsData < handle
    properties (Access = private)
        correlationPairsData
    end
    methods (Access = public)
        function obj = TTCorrelationPairsData(dotNET_object)
            obj.correlationPairsData = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.correlationPairsData)
                obj.correlationPairsData.Dispose();
                obj.correlationPairsData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.correlationPairsData;
        end
        function ret = getCounts(obj, exclude_self_coincidences)
            narginchk(1, 2);
            if nargin == 1
                ret = int32(obj.correlationPairsData.getCounts());
            end
            if nargin == 2
                ret = int32(obj.correlationPairsData.getCounts(exclude_self_coincidences));
            end
        end
        function ret = getG2(obj, exclude_self_coincidences)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.correlationPairsData.getG2());
            end
            if nargin == 2
                ret = double(obj.correlationPairsData.getG2(exclude_self_coincidences));
            end
        end
        function ret = getIndex(obj)
            ret = int64(obj.correlationPairsData.getIndex());
        end
    end
end