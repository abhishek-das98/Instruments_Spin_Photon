classdef TTFrequencyStabilityData < handle
    properties (Access = private)
        frequencyStabilityData
    end
    methods (Access = public)
        function obj = TTFrequencyStabilityData(dotNET_object)
            obj.frequencyStabilityData = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.frequencyStabilityData)
                obj.frequencyStabilityData.Dispose();
                obj.frequencyStabilityData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.frequencyStabilityData;
        end
        function ret = getTau(obj)
            ret = double(obj.frequencyStabilityData.getTau());
        end
        function ret = getADEV(obj)
            ret = double(obj.frequencyStabilityData.getADEV());
        end
        function ret = getMDEV(obj)
            ret = double(obj.frequencyStabilityData.getMDEV());
        end
        function ret = getHDEV(obj)
            ret = double(obj.frequencyStabilityData.getHDEV());
        end
        function ret = getSTDD(obj)
            ret = double(obj.frequencyStabilityData.getSTDD());
        end
        function ret = getADEVScaled(obj)
            ret = double(obj.frequencyStabilityData.getADEVScaled());
        end
        function ret = getTDEV(obj)
            ret = double(obj.frequencyStabilityData.getTDEV());
        end
        function ret = getHDEVScaled(obj)
            ret = double(obj.frequencyStabilityData.getHDEVScaled());
        end
        function ret = getTraceIndex(obj)
            ret = double(obj.frequencyStabilityData.getTraceIndex());
        end
        function ret = getTracePhase(obj)
            ret = double(obj.frequencyStabilityData.getTracePhase());
        end
        function ret = getTraceFrequency(obj)
            ret = double(obj.frequencyStabilityData.getTraceFrequency());
        end
        function ret = getTraceFrequencyAbsolute(obj, input_frequency)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.frequencyStabilityData.getTraceFrequencyAbsolute());
            end
            if nargin == 2
                ret = double(obj.frequencyStabilityData.getTraceFrequencyAbsolute(input_frequency));
            end
        end
    end
end