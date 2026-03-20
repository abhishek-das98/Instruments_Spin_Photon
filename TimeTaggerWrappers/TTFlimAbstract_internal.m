classdef TTFlimAbstract_internal < TTIteratorBase
    properties (Access = private)
        flimAbstract_internal
    end
    methods (Access = public)
        function obj = TTFlimAbstract_internal(dotNET_object)
            obj@TTIteratorBase(dotNET_object); obj.flimAbstract_internal = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.flimAbstract_internal)
                obj.flimAbstract_internal.Dispose();
                obj.flimAbstract_internal = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flimAbstract_internal;
        end
        function ret = isAcquiring(obj)
            ret = logical(obj.flimAbstract_internal.isAcquiring());
        end
    end
end