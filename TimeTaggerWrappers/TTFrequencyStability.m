classdef TTFrequencyStability < TTIteratorBase
    properties (Access = private)
        frequencyStability
    end
    methods (Access = public)
        function obj = TTFrequencyStability(tagger, channel, steps, average, trace_len)
            TimeTagger.loadAssembly();
            narginchk(3, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 3
                dotNET_frequencyStability = SwabianInstruments.TimeTagger.FrequencyStability(tagger, channel, steps);
            end
            if nargin == 4
                dotNET_frequencyStability = SwabianInstruments.TimeTagger.FrequencyStability(tagger, channel, steps, average);
            end
            if nargin == 5
                dotNET_frequencyStability = SwabianInstruments.TimeTagger.FrequencyStability(tagger, channel, steps, average, trace_len);
            end
            obj@TTIteratorBase(dotNET_frequencyStability); obj.frequencyStability = dotNET_frequencyStability;
        end
        function delete(obj)
            if ~isempty(obj.frequencyStability)
                obj.frequencyStability.Dispose();
                obj.frequencyStability = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.frequencyStability;
        end
        function ret = getDataObject(obj)
            ret = TTFrequencyStabilityData(obj.frequencyStability.getDataObject());
        end
    end
end