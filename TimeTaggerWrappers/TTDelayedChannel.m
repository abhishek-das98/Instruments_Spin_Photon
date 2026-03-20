classdef TTDelayedChannel < TTDelayedChannels
    properties (Access = private)
        delayedChannel
    end
    methods (Access = public)
        function obj = TTDelayedChannel(tagger, input_channel, delay)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_delayedChannel = SwabianInstruments.TimeTagger.DelayedChannel(tagger, input_channel, delay);
            obj@TTDelayedChannels(dotNET_delayedChannel); obj.delayedChannel = dotNET_delayedChannel;
        end
        function delete(obj)
            if ~isempty(obj.delayedChannel)
                obj.delayedChannel.Dispose();
                obj.delayedChannel = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.delayedChannel;
        end
        function ret = getChannel(obj)
            ret = int32(obj.delayedChannel.getChannel());
        end
    end
end