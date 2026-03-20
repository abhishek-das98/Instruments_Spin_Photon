classdef TTScope < TTIteratorBase
    properties (Access = private)
        scope
    end
    methods (Access = public)
        function obj = TTScope(tagger, event_channels, trigger_channel, window_size, n_traces, n_max_events)
            TimeTagger.loadAssembly();
            narginchk(3, 6);
            tagger = tagger.getDotNETObject();
            if nargin == 3
                dotNET_scope = SwabianInstruments.TimeTagger.Scope(tagger, event_channels, trigger_channel);
            end
            if nargin == 4
                dotNET_scope = SwabianInstruments.TimeTagger.Scope(tagger, event_channels, trigger_channel, window_size);
            end
            if nargin == 5
                dotNET_scope = SwabianInstruments.TimeTagger.Scope(tagger, event_channels, trigger_channel, window_size, n_traces);
            end
            if nargin == 6
                dotNET_scope = SwabianInstruments.TimeTagger.Scope(tagger, event_channels, trigger_channel, window_size, n_traces, n_max_events);
            end
            obj@TTIteratorBase(dotNET_scope); obj.scope = dotNET_scope;
        end
        function delete(obj)
            if ~isempty(obj.scope)
                obj.scope.Dispose();
                obj.scope = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.scope;
        end
        function ret = getData(obj)
            ret = obj.scope.getData();
        end
        function ret = ready(obj)
            ret = logical(obj.scope.ready());
        end
        function ret = triggered(obj)
            ret = int32(obj.scope.triggered());
        end
        function ret = getWindowSize(obj)
            ret = int64(obj.scope.getWindowSize());
        end
    end
end