classdef TTStartStop < TTIteratorBase
    properties (Access = private)
        startStop
    end
    methods (Access = public)
        function obj = TTStartStop(tagger, click_channel, start_channel, binwidth)
            TimeTagger.loadAssembly();
            narginchk(2, 4);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_startStop = SwabianInstruments.TimeTagger.StartStop(tagger, click_channel);
            end
            if nargin == 3
                dotNET_startStop = SwabianInstruments.TimeTagger.StartStop(tagger, click_channel, start_channel);
            end
            if nargin == 4
                dotNET_startStop = SwabianInstruments.TimeTagger.StartStop(tagger, click_channel, start_channel, binwidth);
            end
            obj@TTIteratorBase(dotNET_startStop); obj.startStop = dotNET_startStop;
        end
        function delete(obj)
            if ~isempty(obj.startStop)
                obj.startStop.Dispose();
                obj.startStop = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.startStop;
        end
        function ret = getData(obj)
            ret = int64(obj.startStop.getData());
        end
    end
end