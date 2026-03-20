classdef TTSyntheticSingleTag < TTIteratorBase
    properties (Access = private)
        syntheticSingleTag
    end
    methods (Access = public)
        function obj = TTSyntheticSingleTag(tagger, base_channel)
            TimeTagger.loadAssembly();
            narginchk(1, 2);
            tagger = tagger.getDotNETObject();
            if nargin == 1
                dotNET_syntheticSingleTag = SwabianInstruments.TimeTagger.SyntheticSingleTag(tagger);
            end
            if nargin == 2
                dotNET_syntheticSingleTag = SwabianInstruments.TimeTagger.SyntheticSingleTag(tagger, base_channel);
            end
            obj@TTIteratorBase(dotNET_syntheticSingleTag); obj.syntheticSingleTag = dotNET_syntheticSingleTag;
        end
        function delete(obj)
            if ~isempty(obj.syntheticSingleTag)
                obj.syntheticSingleTag.Dispose();
                obj.syntheticSingleTag = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.syntheticSingleTag;
        end
        function trigger(obj)
            obj.syntheticSingleTag.trigger();
        end
        function ret = getChannel(obj)
            ret = int32(obj.syntheticSingleTag.getChannel());
        end
    end
end