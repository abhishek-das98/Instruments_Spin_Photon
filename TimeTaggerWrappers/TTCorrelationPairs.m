classdef TTCorrelationPairs < TTIteratorBase
    properties (Access = private)
        correlationPairs
    end
    methods (Access = public)
        function obj = TTCorrelationPairs(tagger, channels, binwidth, n_bins)
            TimeTagger.loadAssembly();
            narginchk(2, 4);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_correlationPairs = SwabianInstruments.TimeTagger.CorrelationPairs(tagger, channels);
            end
            if nargin == 3
                dotNET_correlationPairs = SwabianInstruments.TimeTagger.CorrelationPairs(tagger, channels, binwidth);
            end
            if nargin == 4
                dotNET_correlationPairs = SwabianInstruments.TimeTagger.CorrelationPairs(tagger, channels, binwidth, n_bins);
            end
            obj@TTIteratorBase(dotNET_correlationPairs); obj.correlationPairs = dotNET_correlationPairs;
        end
        function delete(obj)
            if ~isempty(obj.correlationPairs)
                obj.correlationPairs.Dispose();
                obj.correlationPairs = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.correlationPairs;
        end
        function ret = getDataObject(obj)
            ret = TTCorrelationPairsData(obj.correlationPairs.getDataObject());
        end
        function ret = getIndex(obj)
            ret = int64(obj.correlationPairs.getIndex());
        end
    end
end