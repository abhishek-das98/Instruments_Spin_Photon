classdef TTHistogram2D < TTIteratorBase
    properties (Access = private)
        histogram2D
    end
    methods (Access = public)
        function obj = TTHistogram2D(tagger, start_channel, stop_channel_1, stop_channel_2, binwidth_1, binwidth_2, n_bins_1, n_bins_2)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_histogram2D = SwabianInstruments.TimeTagger.Histogram2D(tagger, start_channel, stop_channel_1, stop_channel_2, binwidth_1, binwidth_2, n_bins_1, n_bins_2);
            obj@TTIteratorBase(dotNET_histogram2D); obj.histogram2D = dotNET_histogram2D;
        end
        function delete(obj)
            if ~isempty(obj.histogram2D)
                obj.histogram2D.Dispose();
                obj.histogram2D = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogram2D;
        end
        function ret = getData(obj)
            ret = int32(obj.histogram2D.getData());
        end
        function ret = getIndex(obj)
            ret = int64(obj.histogram2D.getIndex());
        end
        function ret = getIndex_1(obj)
            ret = int64(obj.histogram2D.getIndex_1());
        end
        function ret = getIndex_2(obj)
            ret = int64(obj.histogram2D.getIndex_2());
        end
    end
end