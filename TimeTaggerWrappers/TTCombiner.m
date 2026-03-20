classdef TTCombiner < TTIteratorBase
    properties (Access = private)
        combiner
    end
    methods (Access = public)
        function obj = TTCombiner(tagger, channels)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_combiner = SwabianInstruments.TimeTagger.Combiner(tagger, channels);
            obj@TTIteratorBase(dotNET_combiner); obj.combiner = dotNET_combiner;
        end
        function delete(obj)
            if ~isempty(obj.combiner)
                obj.combiner.Dispose();
                obj.combiner = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.combiner;
        end
        function ret = getChannelCounts(obj)
            ret = int64(obj.combiner.getChannelCounts());
        end
        function ret = getData(obj)
            ret = int64(obj.combiner.getData());
        end
        function ret = getChannel(obj)
            ret = int32(obj.combiner.getChannel());
        end
    end
end