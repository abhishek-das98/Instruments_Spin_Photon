classdef TTGatedChannel < TTIteratorBase
    properties (Access = private)
        gatedChannel
    end
    methods (Access = public)
        function obj = TTGatedChannel(tagger, input_channel, gate_start_channel, gate_stop_channel, initial)
            TimeTagger.loadAssembly();
            narginchk(4, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 4
                dotNET_gatedChannel = SwabianInstruments.TimeTagger.GatedChannel(tagger, input_channel, gate_start_channel, gate_stop_channel);
            end
            if nargin == 5
                initial = SwabianInstruments.TimeTagger.GatedChannelInitial.(char(initial));
                dotNET_gatedChannel = SwabianInstruments.TimeTagger.GatedChannel(tagger, input_channel, gate_start_channel, gate_stop_channel, initial);
            end
            obj@TTIteratorBase(dotNET_gatedChannel); obj.gatedChannel = dotNET_gatedChannel;
        end
        function delete(obj)
            if ~isempty(obj.gatedChannel)
                obj.gatedChannel.Dispose();
                obj.gatedChannel = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.gatedChannel;
        end
        function ret = getChannel(obj)
            ret = int32(obj.gatedChannel.getChannel());
        end
    end
end