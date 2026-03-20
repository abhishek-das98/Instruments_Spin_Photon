classdef TTTimeDifferences < TTIteratorBase
    properties (Access = private)
        timeDifferences
    end
    methods (Access = public)
        function obj = TTTimeDifferences(tagger, click_channel, start_channel, next_channel, sync_channel, binwidth, n_bins, n_histograms)
            TimeTagger.loadAssembly();
            narginchk(2, 8);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel);
            end
            if nargin == 3
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel);
            end
            if nargin == 4
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel, next_channel);
            end
            if nargin == 5
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel, next_channel, sync_channel);
            end
            if nargin == 6
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel, next_channel, sync_channel, binwidth);
            end
            if nargin == 7
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel, next_channel, sync_channel, binwidth, n_bins);
            end
            if nargin == 8
                dotNET_timeDifferences = SwabianInstruments.TimeTagger.TimeDifferences(tagger, click_channel, start_channel, next_channel, sync_channel, binwidth, n_bins, n_histograms);
            end
            obj@TTIteratorBase(dotNET_timeDifferences); obj.timeDifferences = dotNET_timeDifferences;
        end
        function delete(obj)
            if ~isempty(obj.timeDifferences)
                obj.timeDifferences.Dispose();
                obj.timeDifferences = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeDifferences;
        end
        function ret = getData(obj)
            ret = int32(obj.timeDifferences.getData());
        end
        function ret = getIndex(obj)
            ret = int64(obj.timeDifferences.getIndex());
        end
        function setMaxCounts(obj, max_counts)
            obj.timeDifferences.setMaxCounts(max_counts);
        end
        function setMaxRollovers(obj, max_rollovers)
            obj.timeDifferences.setMaxRollovers(max_rollovers);
        end
        function ret = getHistogramIndex(obj)
            ret = int32(obj.timeDifferences.getHistogramIndex());
        end
        function ret = getCounts(obj)
            ret = uint64(obj.timeDifferences.getCounts());
        end
        function ret = ready(obj)
            ret = logical(obj.timeDifferences.ready());
        end
    end
end