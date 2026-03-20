classdef TTFileReader < handle
    properties (Access = private)
        fileReader
    end
    methods (Access = public)
        function obj = TTFileReader(filenames)
            TimeTagger.loadAssembly();
            dotNET_fileReader = SwabianInstruments.TimeTagger.FileReader(filenames);
            obj.fileReader = dotNET_fileReader;
        end
        function delete(obj)
            if ~isempty(obj.fileReader)
                obj.fileReader.Dispose();
                obj.fileReader = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.fileReader;
        end
        function ret = getData(obj, n_events)
            if n_events >= 256*1024*1024
                error('The number of events (''n_events''= %s) in getData() exceeds the supported limit (%s).', n_events, 256*1024*1024-1);
            end
            ret = TTTimeTagStreamBuffer(obj.fileReader.getData(n_events));
        end
        function ret = hasData(obj)
            ret = logical(obj.fileReader.hasData());
        end
        function ret = getConfiguration(obj)
            ret = char(obj.fileReader.getConfiguration());
        end
        function ret = getChannelList(obj)
            ret = int32(obj.fileReader.getChannelList());
        end
        function ret = getLastMarker(obj)
            ret = char(obj.fileReader.getLastMarker());
        end
    end
end