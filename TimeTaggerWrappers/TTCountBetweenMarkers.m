classdef TTCountBetweenMarkers < TTIteratorBase
    properties (Access = private)
        countBetweenMarkers
    end
    methods (Access = public)
        function obj = TTCountBetweenMarkers(tagger, click_channel, begin_channel, end_channel, n_values)
            TimeTagger.loadAssembly();
            narginchk(3, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 3
                dotNET_countBetweenMarkers = SwabianInstruments.TimeTagger.CountBetweenMarkers(tagger, click_channel, begin_channel);
            end
            if nargin == 4
                dotNET_countBetweenMarkers = SwabianInstruments.TimeTagger.CountBetweenMarkers(tagger, click_channel, begin_channel, end_channel);
            end
            if nargin == 5
                dotNET_countBetweenMarkers = SwabianInstruments.TimeTagger.CountBetweenMarkers(tagger, click_channel, begin_channel, end_channel, n_values);
            end
            obj@TTIteratorBase(dotNET_countBetweenMarkers); obj.countBetweenMarkers = dotNET_countBetweenMarkers;
        end
        function delete(obj)
            if ~isempty(obj.countBetweenMarkers)
                obj.countBetweenMarkers.Dispose();
                obj.countBetweenMarkers = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.countBetweenMarkers;
        end
        function ret = getData(obj)
            ret = int32(obj.countBetweenMarkers.getData());
        end
        function ret = getIndex(obj)
            ret = int64(obj.countBetweenMarkers.getIndex());
        end
        function ret = getBinWidths(obj)
            ret = int64(obj.countBetweenMarkers.getBinWidths());
        end
        function ret = ready(obj)
            ret = logical(obj.countBetweenMarkers.ready());
        end
    end
end