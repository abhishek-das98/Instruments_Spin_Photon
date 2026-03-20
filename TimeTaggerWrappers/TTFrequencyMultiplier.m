classdef TTFrequencyMultiplier < TTIteratorBase
    properties (Access = private)
        frequencyMultiplier
    end
    methods (Access = public)
        function obj = TTFrequencyMultiplier(tagger, input_channel, multiplier)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_frequencyMultiplier = SwabianInstruments.TimeTagger.FrequencyMultiplier(tagger, input_channel, multiplier);
            obj@TTIteratorBase(dotNET_frequencyMultiplier); obj.frequencyMultiplier = dotNET_frequencyMultiplier;
        end
        function delete(obj)
            if ~isempty(obj.frequencyMultiplier)
                obj.frequencyMultiplier.Dispose();
                obj.frequencyMultiplier = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.frequencyMultiplier;
        end
        function ret = getChannel(obj)
            ret = int32(obj.frequencyMultiplier.getChannel());
        end
        function ret = getMultiplier(obj)
            ret = int32(obj.frequencyMultiplier.getMultiplier());
        end
    end
end