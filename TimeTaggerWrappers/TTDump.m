classdef TTDump < TTIteratorBase
    properties (Access = private)
        dump
    end
    methods (Access = public)
        function obj = TTDump(tagger, filename, max_tags, channels)
            TimeTagger.loadAssembly();
            narginchk(3, 4);
            tagger = tagger.getDotNETObject();
            if nargin == 3
                dotNET_dump = SwabianInstruments.TimeTagger.Dump(tagger, filename, max_tags);
            end
            if nargin == 4
                dotNET_dump = SwabianInstruments.TimeTagger.Dump(tagger, filename, max_tags, channels);
            end
            obj@TTIteratorBase(dotNET_dump); obj.dump = dotNET_dump;
        end
        function delete(obj)
            if ~isempty(obj.dump)
                obj.dump.Dispose();
                obj.dump = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.dump;
        end
    end
end