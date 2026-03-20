classdef TTConstantFractionDiscriminator < TTIteratorBase
    properties (Access = private)
        constantFractionDiscriminator
    end
    methods (Access = public)
        function obj = TTConstantFractionDiscriminator(tagger, channels, search_window)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_constantFractionDiscriminator = SwabianInstruments.TimeTagger.ConstantFractionDiscriminator(tagger, channels, search_window);
            obj@TTIteratorBase(dotNET_constantFractionDiscriminator); obj.constantFractionDiscriminator = dotNET_constantFractionDiscriminator;
        end
        function delete(obj)
            if ~isempty(obj.constantFractionDiscriminator)
                obj.constantFractionDiscriminator.Dispose();
                obj.constantFractionDiscriminator = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.constantFractionDiscriminator;
        end
        function ret = getChannels(obj)
            ret = int32(obj.constantFractionDiscriminator.getChannels());
        end
    end
end