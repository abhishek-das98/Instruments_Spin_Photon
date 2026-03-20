classdef TTCoincidences < TTIteratorBase
    properties (Access = private)
        coincidences
    end
    methods (Access = public)
        function obj = TTCoincidences(tagger, coincidenceGroups, coincidenceWindow, timestamp)
            TimeTagger.loadAssembly();
            assert(nargin == 1 || (3 <= nargin && nargin <= 4), 'Incorrect number of arguments')
            if nargin == 1
                assert(isa(tagger, 'SwabianInstruments.TimeTagger.IteratorBase'), 'Argument tagger should be of type SwabianInstruments.TimeTagger.IteratorBase')
                dotNET_coincidences = tagger;
            else
                tagger = tagger.getDotNETObject();
                coincidenceGroups = TTCoincidences.cast_NET_array(coincidenceGroups, NET.createArray('System.Int32[]', length(coincidenceGroups)));
                if nargin == 3
                    dotNET_coincidences = SwabianInstruments.TimeTagger.Coincidences(tagger, coincidenceGroups, coincidenceWindow);
                end
                if nargin == 4
                    timestamp = SwabianInstruments.TimeTagger.CoincidenceTimestamp.(char(timestamp));
                    dotNET_coincidences = SwabianInstruments.TimeTagger.Coincidences(tagger, coincidenceGroups, coincidenceWindow, timestamp);
                end
            end
            obj@TTIteratorBase(dotNET_coincidences); obj.coincidences = dotNET_coincidences;
        end
        function delete(obj)
            if ~isempty(obj.coincidences)
                obj.coincidences.Dispose();
                obj.coincidences = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.coincidences;
        end
        function ret = getChannels(obj)
            ret = int32(obj.coincidences.getChannels());
        end
        function setCoincidenceWindow(obj, coincidenceWindow)
            obj.coincidences.setCoincidenceWindow(coincidenceWindow);
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