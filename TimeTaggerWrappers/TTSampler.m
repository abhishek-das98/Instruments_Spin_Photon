classdef TTSampler < TTIteratorBase
    properties (Access = private)
        sampler
    end
    methods (Access = public)
        function obj = TTSampler(tagger, trigger, channels, max_triggers)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_sampler = SwabianInstruments.TimeTagger.Sampler(tagger, trigger, channels, max_triggers);
            obj@TTIteratorBase(dotNET_sampler); obj.sampler = dotNET_sampler;
        end
        function delete(obj)
            if ~isempty(obj.sampler)
                obj.sampler.Dispose();
                obj.sampler = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.sampler;
        end
        function ret = getData(obj)
            ret = int64(obj.sampler.getData());
        end
        function ret = getDataAsMask(obj)
            ret = int64(obj.sampler.getDataAsMask());
        end
    end
end