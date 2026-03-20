classdef TTTimeDifferencesND < TTIteratorBase
    properties (Access = private)
        timeDifferencesND
    end
    methods (Access = public)
        function obj = TTTimeDifferencesND(tagger, click_channel, start_channel, next_channels, sync_channels, n_histograms, binwidth, n_bins)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_timeDifferencesND = SwabianInstruments.TimeTagger.TimeDifferencesND(tagger, click_channel, start_channel, next_channels, sync_channels, n_histograms, binwidth, n_bins);
            obj@TTIteratorBase(dotNET_timeDifferencesND); obj.timeDifferencesND = dotNET_timeDifferencesND;
        end
        function delete(obj)
            if ~isempty(obj.timeDifferencesND)
                obj.timeDifferencesND.Dispose();
                obj.timeDifferencesND = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeDifferencesND;
        end
        function ret = getData(obj)
            ret = int32(obj.timeDifferencesND.getData());
        end
        function ret = getIndex(obj)
            ret = int64(obj.timeDifferencesND.getIndex());
        end
        function setMaxRollovers(obj, max_rollovers)
            obj.timeDifferencesND.setMaxRollovers(max_rollovers);
        end
        function ret = getHistogramIndex(obj)
            ret = int32(obj.timeDifferencesND.getHistogramIndex());
        end
        function ret = getRollovers(obj)
            ret = uint64(obj.timeDifferencesND.getRollovers());
        end
    end
end