classdef TTOverflowInjector < TTIteratorBase
    properties (Access = private)
        overflowInjector
    end
    methods (Access = public)
        function obj = TTOverflowInjector(tagger, delay, length)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_overflowInjector = SwabianInstruments.TimeTagger.OverflowInjector(tagger, delay, length);
            obj@TTIteratorBase(dotNET_overflowInjector); obj.overflowInjector = dotNET_overflowInjector;
        end
        function delete(obj)
            if ~isempty(obj.overflowInjector)
                obj.overflowInjector.Dispose();
                obj.overflowInjector = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.overflowInjector;
        end
    end
end