classdef TTTimeTagStream < TTIteratorBase
    properties (Access = private)
        timeTagStream
    end
    methods (Access = public)
        function obj = TTTimeTagStream(tagger, n_max_events, channels)
            if n_max_events >= 256*1024*1024
                error('The maximum number of events specified (''n_max_events''=%s) exceeds the supported limit (%s).',n_max_events, 256*1024*1024-1);
            end
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_timeTagStream = SwabianInstruments.TimeTagger.TimeTagStream(tagger, n_max_events, channels);
            obj@TTIteratorBase(dotNET_timeTagStream); obj.timeTagStream = dotNET_timeTagStream;
        end
        function delete(obj)
            if ~isempty(obj.timeTagStream)
                obj.timeTagStream.Dispose();
                obj.timeTagStream = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTagStream;
        end
        function ret = getData(obj)
            ret = TTTimeTagStreamBuffer(obj.timeTagStream.getData());
        end
        function ret = getCounts(obj)
            ret = uint64(obj.timeTagStream.getCounts());
        end
    end
end