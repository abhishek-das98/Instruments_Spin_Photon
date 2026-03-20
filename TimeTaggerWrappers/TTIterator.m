classdef TTIterator < TTIteratorBase
    properties (Access = private)
        iterator
    end
    methods (Access = public)
        function obj = TTIterator(tagger, channel)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_iterator = SwabianInstruments.TimeTagger.Iterator(tagger, channel);
            obj@TTIteratorBase(dotNET_iterator); obj.iterator = dotNET_iterator;
        end
        function delete(obj)
            if ~isempty(obj.iterator)
                obj.iterator.Dispose();
                obj.iterator = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.iterator;
        end
        function ret = next(obj)
            ret = int64(obj.iterator.next());
        end
        function ret = size(obj)
            ret = uint64(obj.iterator.size());
        end
    end
end