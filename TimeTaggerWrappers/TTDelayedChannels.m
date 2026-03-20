classdef TTDelayedChannels < TTIteratorBase
    properties (Access = private)
        delayedChannels
    end
    methods (Access = public)
        function obj = TTDelayedChannels(tagger, input_channels, delay)
            TimeTagger.loadAssembly();
            assert(nargin == 1 || (3 <= nargin && nargin <= 3), 'Incorrect number of arguments')
            if nargin == 1
                assert(isa(tagger, 'SwabianInstruments.TimeTagger.IteratorBase'), 'Argument tagger should be of type SwabianInstruments.TimeTagger.IteratorBase')
                dotNET_delayedChannels = tagger;
            else
                tagger = tagger.getDotNETObject();
                dotNET_delayedChannels = SwabianInstruments.TimeTagger.DelayedChannels(tagger, input_channels, delay);
            end
            obj@TTIteratorBase(dotNET_delayedChannels); obj.delayedChannels = dotNET_delayedChannels;
        end
        function delete(obj)
            if ~isempty(obj.delayedChannels)
                obj.delayedChannels.Dispose();
                obj.delayedChannels = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.delayedChannels;
        end
        function ret = getChannels(obj)
            ret = int32(obj.delayedChannels.getChannels());
        end
        function setDelay(obj, delay)
            obj.delayedChannels.setDelay(delay);
        end
    end
end