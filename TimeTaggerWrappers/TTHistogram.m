classdef TTHistogram < TTIteratorBase
    properties (Access = private)
        histogram
    end
    methods (Access = public)
        function obj = TTHistogram(tagger, click_channel, start_channel, binwidth, n_bins)
            TimeTagger.loadAssembly();
            narginchk(2, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_histogram = SwabianInstruments.TimeTagger.Histogram(tagger, click_channel);
            end
            if nargin == 3
                dotNET_histogram = SwabianInstruments.TimeTagger.Histogram(tagger, click_channel, start_channel);
            end
            if nargin == 4
                dotNET_histogram = SwabianInstruments.TimeTagger.Histogram(tagger, click_channel, start_channel, binwidth);
            end
            if nargin == 5
                dotNET_histogram = SwabianInstruments.TimeTagger.Histogram(tagger, click_channel, start_channel, binwidth, n_bins);
            end
            obj@TTIteratorBase(dotNET_histogram); obj.histogram = dotNET_histogram;
        end
        function delete(obj)
            if ~isempty(obj.histogram)
                obj.histogram.Dispose();
                obj.histogram = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogram;
        end
        function ret = getData(obj)
            ret = int32(obj.histogram.getData());
        end
        function ret = getIndex(obj)
            ret = int64(obj.histogram.getIndex());
        end
    end
end