classdef TTCombinations < TTIteratorBase
    properties (Access = private)
        combinations
    end
    methods (Access = public)
        function obj = TTCombinations(tagger, channels, window_size)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_combinations = SwabianInstruments.TimeTagger.Combinations(tagger, channels, window_size);
            obj@TTIteratorBase(dotNET_combinations); obj.combinations = dotNET_combinations;
        end
        function delete(obj)
            if ~isempty(obj.combinations)
                obj.combinations.Dispose();
                obj.combinations = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.combinations;
        end
        function ret = getChannel(obj, input_channels)
            ret = int32(obj.combinations.getChannel(input_channels));
        end
        function ret = getChannels(obj, list_of_input_channel_sets)
            list_of_input_channel_sets = TTCombinations.cast_NET_array(list_of_input_channel_sets, NET.createArray('System.Int32[]', length(list_of_input_channel_sets)));
            ret = int32(obj.combinations.getChannels(list_of_input_channel_sets));
        end
        function ret = getChannelByMask(obj, input_mask)
            ret = int32(obj.combinations.getChannelByMask(input_mask));
        end
        function ret = getCombination(obj, virtual_channel)
            ret = int32(obj.combinations.getCombination(virtual_channel));
        end
        function ret = getSumChannel(obj, n_channels)
            ret = int32(obj.combinations.getSumChannel(n_channels));
        end
    end
    methods (Static, Access = private)
        function ret = cast_NET_array(cell_array, net_array)
            for i = 1:length(cell_array)
                net_array(i) = cell_array{i};
            end
            ret = net_array;
        end
    end
end