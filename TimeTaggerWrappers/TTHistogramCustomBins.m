classdef TTHistogramCustomBins < TTHistogramLogBins
    properties (Access = private)
        histogramCustomBins
    end
    methods (Access = public)
        function obj = TTHistogramCustomBins(tagger, click_channel, start_channel, binedges, click_gate, start_gate)
            TimeTagger.loadAssembly();
            narginchk(4, 6);
            tagger = tagger.getDotNETObject();
            if nargin == 4
                dotNET_histogramCustomBins = SwabianInstruments.TimeTagger.HistogramCustomBins(tagger, click_channel, start_channel, binedges);
            end
            if nargin == 5
                click_gate = click_gate.getDotNETObject();
                dotNET_histogramCustomBins = SwabianInstruments.TimeTagger.HistogramCustomBins(tagger, click_channel, start_channel, binedges, click_gate);
            end
            if nargin == 6
                click_gate = click_gate.getDotNETObject();
                start_gate = start_gate.getDotNETObject();
                dotNET_histogramCustomBins = SwabianInstruments.TimeTagger.HistogramCustomBins(tagger, click_channel, start_channel, binedges, click_gate, start_gate);
            end
            obj@TTHistogramLogBins(dotNET_histogramCustomBins); obj.histogramCustomBins = dotNET_histogramCustomBins;
        end
        function delete(obj)
            if ~isempty(obj.histogramCustomBins)
                obj.histogramCustomBins.Dispose();
                obj.histogramCustomBins = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.histogramCustomBins;
        end
    end
end