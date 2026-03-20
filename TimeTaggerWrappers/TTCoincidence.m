classdef TTCoincidence < TTCoincidences
    properties (Access = private)
        coincidence
    end
    methods (Access = public)
        function obj = TTCoincidence(tagger, channels, coincidenceWindow, timestamp)
            TimeTagger.loadAssembly();
            narginchk(2, 4);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_coincidence = SwabianInstruments.TimeTagger.Coincidence(tagger, channels);
            end
            if nargin == 3
                dotNET_coincidence = SwabianInstruments.TimeTagger.Coincidence(tagger, channels, coincidenceWindow);
            end
            if nargin == 4
                timestamp = SwabianInstruments.TimeTagger.CoincidenceTimestamp.(char(timestamp));
                dotNET_coincidence = SwabianInstruments.TimeTagger.Coincidence(tagger, channels, coincidenceWindow, timestamp);
            end
            obj@TTCoincidences(dotNET_coincidence); obj.coincidence = dotNET_coincidence;
        end
        function delete(obj)
            if ~isempty(obj.coincidence)
                obj.coincidence.Dispose();
                obj.coincidence = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.coincidence;
        end
        function ret = getChannel(obj)
            ret = int32(obj.coincidence.getChannel());
        end
    end
end