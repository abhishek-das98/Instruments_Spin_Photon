classdef TTHistogramND < TTIteratorBase
    properties (Access = private)
        histogramND
    end
    methods (Access = public)
        function obj = TTHistogramND(tagger, start_channel, stop_channels, binwidths, n_bins)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_histogramND = SwabianInstruments.TimeTagger.HistogramND(tagger, start_channel, stop_channels, binwidths, n_bins);
            obj@TTIteratorBase(dotNET_histogramND); obj.histogramND = dotNET_histogramND;
        end
        function delete(obj)
            if ~isempty(obj.histogramND)
                obj.histogramND.Dispose();
                obj.histogramND = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogramND;
        end
        function ret = getData(obj)
            ret = int32(obj.histogramND.getData());
        end
        function ret = getIndex(obj, dim)
            narginchk(1, 2);
            if nargin == 1
                ret = int64(obj.histogramND.getIndex());
            end
            if nargin == 2
                ret = int64(obj.histogramND.getIndex(dim));
            end
        end
    end
end