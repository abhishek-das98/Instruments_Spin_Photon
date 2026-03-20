classdef TTPhaseNoiseData < handle
    properties (Access = private)
        phaseNoiseData
    end
    methods (Access = public)
        function obj = TTPhaseNoiseData(dotNET_object)
            obj.phaseNoiseData = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.phaseNoiseData)
                obj.phaseNoiseData.Dispose();
                obj.phaseNoiseData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.phaseNoiseData;
        end
        function ret = getPhaseNoise(obj)
            ret = double(obj.phaseNoiseData.getPhaseNoise());
        end
        function ret = getIntegratedJitter(obj, lower_bound, upper_bound)
            narginchk(1, 3);
            if nargin == 1
                ret = double(obj.phaseNoiseData.getIntegratedJitter());
            end
            if nargin == 2
                ret = double(obj.phaseNoiseData.getIntegratedJitter(lower_bound));
            end
            if nargin == 3
                ret = double(obj.phaseNoiseData.getIntegratedJitter(lower_bound, upper_bound));
            end
        end
        function ret = getOffset(obj)
            ret = double(obj.phaseNoiseData.getOffset());
        end
        function ret = getAveragedSequences(obj)
            ret = uint64(obj.phaseNoiseData.getAveragedSequences());
        end
        function ret = getFrequency(obj)
            ret = double(obj.phaseNoiseData.getFrequency());
        end
    end
end