classdef TTEventGenerator < TTIteratorBase
    properties (Access = private)
        eventGenerator
    end
    methods (Access = public)
        function obj = TTEventGenerator(tagger, trigger_channel, pattern, trigger_divider, divider_offset, stop_channel)
            TimeTagger.loadAssembly();
            narginchk(3, 6);
            tagger = tagger.getDotNETObject();
            if nargin == 3
                dotNET_eventGenerator = SwabianInstruments.TimeTagger.EventGenerator(tagger, trigger_channel, pattern);
            end
            if nargin == 4
                dotNET_eventGenerator = SwabianInstruments.TimeTagger.EventGenerator(tagger, trigger_channel, pattern, trigger_divider);
            end
            if nargin == 5
                dotNET_eventGenerator = SwabianInstruments.TimeTagger.EventGenerator(tagger, trigger_channel, pattern, trigger_divider, divider_offset);
            end
            if nargin == 6
                dotNET_eventGenerator = SwabianInstruments.TimeTagger.EventGenerator(tagger, trigger_channel, pattern, trigger_divider, divider_offset, stop_channel);
            end
            obj@TTIteratorBase(dotNET_eventGenerator); obj.eventGenerator = dotNET_eventGenerator;
        end
        function delete(obj)
            if ~isempty(obj.eventGenerator)
                obj.eventGenerator.Dispose();
                obj.eventGenerator = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.eventGenerator;
        end
        function ret = getChannel(obj)
            ret = int32(obj.eventGenerator.getChannel());
        end
    end
end