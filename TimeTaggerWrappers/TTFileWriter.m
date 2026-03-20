classdef TTFileWriter < TTIteratorBase
    properties (Access = private)
        fileWriter
    end
    methods (Access = public)
        function obj = TTFileWriter(tagger, filename, channels)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_fileWriter = SwabianInstruments.TimeTagger.FileWriter(tagger, filename, channels);
            obj@TTIteratorBase(dotNET_fileWriter); obj.fileWriter = dotNET_fileWriter;
        end
        function delete(obj)
            if ~isempty(obj.fileWriter)
                obj.fileWriter.Dispose();
                obj.fileWriter = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.fileWriter;
        end
        function split(obj, new_filename)
            narginchk(1, 2);
            if nargin == 1
                obj.fileWriter.split();
            end
            if nargin == 2
                obj.fileWriter.split(new_filename);
            end
        end
        function setMaxFileSize(obj, max_file_size)
            obj.fileWriter.setMaxFileSize(max_file_size);
        end
        function ret = getMaxFileSize(obj)
            ret = uint64(obj.fileWriter.getMaxFileSize());
        end
        function ret = getTotalEvents(obj)
            ret = uint64(obj.fileWriter.getTotalEvents());
        end
        function ret = getTotalSize(obj)
            ret = uint64(obj.fileWriter.getTotalSize());
        end
        function setMarker(obj, marker)
            obj.fileWriter.setMarker(marker);
        end
    end
end