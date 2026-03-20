classdef TTCorrelation < TTIteratorBase
    properties (Access = private)
        correlation
    end
    methods (Access = public)
        function obj = TTCorrelation(tagger, channel_1, channel_2, binwidth, n_bins)
            TimeTagger.loadAssembly();
            narginchk(2, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_correlation = SwabianInstruments.TimeTagger.Correlation(tagger, channel_1);
            end
            if nargin == 3
                dotNET_correlation = SwabianInstruments.TimeTagger.Correlation(tagger, channel_1, channel_2);
            end
            if nargin == 4
                dotNET_correlation = SwabianInstruments.TimeTagger.Correlation(tagger, channel_1, channel_2, binwidth);
            end
            if nargin == 5
                dotNET_correlation = SwabianInstruments.TimeTagger.Correlation(tagger, channel_1, channel_2, binwidth, n_bins);
            end
            obj@TTIteratorBase(dotNET_correlation); obj.correlation = dotNET_correlation;
        end
        function delete(obj)
            if ~isempty(obj.correlation)
                obj.correlation.Dispose();
                obj.correlation = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.correlation;
        end
        function ret = getData(obj)
            ret = int32(obj.correlation.getData());
        end
        function ret = getDataNormalized(obj)
            ret = double(obj.correlation.getDataNormalized());
        end
        function ret = getIndex(obj)
            ret = int64(obj.correlation.getIndex());
        end
    end
end