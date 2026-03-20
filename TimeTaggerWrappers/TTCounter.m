classdef TTCounter < TTIteratorBase
    properties (Access = private)
        counter
    end
    methods (Access = public)
        function obj = TTCounter(tagger, channels, binwidth, n_values)
            TimeTagger.loadAssembly();
            narginchk(2, 4);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_counter = SwabianInstruments.TimeTagger.Counter(tagger, channels);
            end
            if nargin == 3
                dotNET_counter = SwabianInstruments.TimeTagger.Counter(tagger, channels, binwidth);
            end
            if nargin == 4
                dotNET_counter = SwabianInstruments.TimeTagger.Counter(tagger, channels, binwidth, n_values);
            end
            obj@TTIteratorBase(dotNET_counter); obj.counter = dotNET_counter;
        end
        function delete(obj)
            if ~isempty(obj.counter)
                obj.counter.Dispose();
                obj.counter = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.counter;
        end
        function ret = getData(obj, rolling)
            narginchk(1, 2);
            if nargin == 1
                ret = int32(obj.counter.getData());
            end
            if nargin == 2
                ret = int32(obj.counter.getData(rolling));
            end
        end
        function ret = getIndex(obj)
            ret = int64(obj.counter.getIndex());
        end
        function ret = getDataNormalized(obj, rolling)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.counter.getDataNormalized());
            end
            if nargin == 2
                ret = double(obj.counter.getDataNormalized(rolling));
            end
        end
        function ret = getDataTotalCounts(obj)
            ret = uint64(obj.counter.getDataTotalCounts());
        end
        function ret = getDataObject(obj, remove)
            narginchk(1, 2);
            if nargin == 1
                ret = TTCounterData(obj.counter.getDataObject());
            end
            if nargin == 2
                ret = TTCounterData(obj.counter.getDataObject(remove));
            end
        end
    end
end