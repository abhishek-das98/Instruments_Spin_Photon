classdef TTCountrate < TTIteratorBase
    properties (Access = private)
        countrate
    end
    methods (Access = public)
        function obj = TTCountrate(tagger, channels)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_countrate = SwabianInstruments.TimeTagger.Countrate(tagger, channels);
            obj@TTIteratorBase(dotNET_countrate); obj.countrate = dotNET_countrate;
        end
        function delete(obj)
            if ~isempty(obj.countrate)
                obj.countrate.Dispose();
                obj.countrate = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.countrate;
        end
        function ret = getData(obj)
            ret = double(obj.countrate.getData());
        end
        function ret = getCountsTotal(obj)
            ret = int64(obj.countrate.getCountsTotal());
        end
    end
end