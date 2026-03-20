classdef TTChannelGate < handle
    properties (Access = private)
        channelGate
    end
    properties (Access = public)
        gate_open_channel
        gate_close_channel
        initial
    end
    methods (Access = public)
        function obj = TTChannelGate(gate_open_channel, gate_close_channel, initial)
            TimeTagger.loadAssembly();
            narginchk(2, 3);
            if nargin == 2
                dotNET_channelGate = SwabianInstruments.TimeTagger.ChannelGate(gate_open_channel, gate_close_channel);
            end
            if nargin == 3
                initial = SwabianInstruments.TimeTagger.GatedChannelInitial.(char(initial));
                dotNET_channelGate = SwabianInstruments.TimeTagger.ChannelGate(gate_open_channel, gate_close_channel, initial);
            end
            obj.channelGate = dotNET_channelGate;
            obj.gate_open_channel = int32(channelGate.gate_open_channel);
            obj.gate_close_channel = int32(channelGate.gate_close_channel);
            obj.initial = TTGatedChannelInitial(channelGate.initial);
        end
        function delete(obj)
            if ~isempty(obj.channelGate)
                obj.channelGate.Dispose();
                obj.channelGate = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.channelGate;
        end
    end
end