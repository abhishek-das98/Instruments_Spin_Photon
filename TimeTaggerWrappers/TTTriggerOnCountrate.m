classdef TTTriggerOnCountrate < TTIteratorBase
    properties (Access = private)
        triggerOnCountrate
    end
    methods (Access = public)
        function obj = TTTriggerOnCountrate(tagger, input_channel, reference_countrate, hysteresis, time_window)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_triggerOnCountrate = SwabianInstruments.TimeTagger.TriggerOnCountrate(tagger, input_channel, reference_countrate, hysteresis, time_window);
            obj@TTIteratorBase(dotNET_triggerOnCountrate); obj.triggerOnCountrate = dotNET_triggerOnCountrate;
        end
        function delete(obj)
            if ~isempty(obj.triggerOnCountrate)
                obj.triggerOnCountrate.Dispose();
                obj.triggerOnCountrate = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.triggerOnCountrate;
        end
        function ret = getChannelAbove(obj)
            ret = int32(obj.triggerOnCountrate.getChannelAbove());
        end
        function ret = getChannelBelow(obj)
            ret = int32(obj.triggerOnCountrate.getChannelBelow());
        end
        function ret = getChannels(obj)
            ret = int32(obj.triggerOnCountrate.getChannels());
        end
        function ret = getCurrentCountrate(obj)
            ret = double(obj.triggerOnCountrate.getCurrentCountrate());
        end
        function ret = injectCurrentState(obj)
            ret = logical(obj.triggerOnCountrate.injectCurrentState());
        end
        function ret = isAbove(obj)
            ret = logical(obj.triggerOnCountrate.isAbove());
        end
        function ret = isBelow(obj)
            ret = logical(obj.triggerOnCountrate.isBelow());
        end
    end
end