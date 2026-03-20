classdef TTHistogramLogBins < TTIteratorBase
    properties (Access = private)
        histogramLogBins
    end
    methods (Access = public)
        function obj = TTHistogramLogBins(tagger, click_channel, start_channel, exp_start, exp_stop, n_bins, click_gate, start_gate)
            TimeTagger.loadAssembly();
            assert(nargin == 1 || (6 <= nargin && nargin <= 8), 'Incorrect number of arguments')
            if nargin == 1
                assert(isa(tagger, 'SwabianInstruments.TimeTagger.IteratorBase'), 'Argument tagger should be of type SwabianInstruments.TimeTagger.IteratorBase')
                dotNET_histogramLogBins = tagger;
            else
                tagger = tagger.getDotNETObject();
                if nargin == 6
                    dotNET_histogramLogBins = SwabianInstruments.TimeTagger.HistogramLogBins(tagger, click_channel, start_channel, exp_start, exp_stop, n_bins);
                end
                if nargin == 7
                    click_gate = click_gate.getDotNETObject();
                    dotNET_histogramLogBins = SwabianInstruments.TimeTagger.HistogramLogBins(tagger, click_channel, start_channel, exp_start, exp_stop, n_bins, click_gate);
                end
                if nargin == 8
                    click_gate = click_gate.getDotNETObject();
                    start_gate = start_gate.getDotNETObject();
                    dotNET_histogramLogBins = SwabianInstruments.TimeTagger.HistogramLogBins(tagger, click_channel, start_channel, exp_start, exp_stop, n_bins, click_gate, start_gate);
                end
            end
            obj@TTIteratorBase(dotNET_histogramLogBins); obj.histogramLogBins = dotNET_histogramLogBins;
        end
        function delete(obj)
            if ~isempty(obj.histogramLogBins)
                obj.histogramLogBins.Dispose();
                obj.histogramLogBins = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogramLogBins;
        end
        function ret = getDataObject(obj)
            ret = TTHistogramLogBinsData(obj.histogramLogBins.getDataObject());
        end
        function ret = getBinEdges(obj)
            ret = int64(obj.histogramLogBins.getBinEdges());
        end
        function ret = getData(obj)
            ret = uint64(obj.histogramLogBins.getData());
        end
        function ret = getDataNormalizedCountsPerPs(obj)
            ret = double(obj.histogramLogBins.getDataNormalizedCountsPerPs());
        end
        function ret = getDataNormalizedG2(obj)
            ret = double(obj.histogramLogBins.getDataNormalizedG2());
        end
    end
end