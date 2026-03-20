classdef TTConditionalFilterChannel < TTIteratorBase
    properties (Access = private)
        conditionalFilterChannel
    end
    methods (Access = public)
        function obj = TTConditionalFilterChannel(tagger, filter_channels, trigger_channels)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_conditionalFilterChannel = SwabianInstruments.TimeTagger.ConditionalFilterChannel(tagger, filter_channels, trigger_channels);
            obj@TTIteratorBase(dotNET_conditionalFilterChannel); obj.conditionalFilterChannel = dotNET_conditionalFilterChannel;
        end
        function delete(obj)
            if ~isempty(obj.conditionalFilterChannel)
                obj.conditionalFilterChannel.Dispose();
                obj.conditionalFilterChannel = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.conditionalFilterChannel;
        end
        function ret = getChannel(obj)
            ret = int32(obj.conditionalFilterChannel.getChannel());
        end
        function ret = getChannels(obj)
            ret = int32(obj.conditionalFilterChannel.getChannels());
        end
    end
end