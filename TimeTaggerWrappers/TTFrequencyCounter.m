classdef TTFrequencyCounter < TTIteratorBase
    properties (Access = private)
        frequencyCounter
    end
    methods (Access = public)
        function obj = TTFrequencyCounter(tagger, channels, sampling_interval, fitting_window, n_values)
            TimeTagger.loadAssembly();
            narginchk(4, 5);
            tagger = tagger.getDotNETObject();
            if nargin == 4
                dotNET_frequencyCounter = SwabianInstruments.TimeTagger.FrequencyCounter(tagger, channels, sampling_interval, fitting_window);
            end
            if nargin == 5
                dotNET_frequencyCounter = SwabianInstruments.TimeTagger.FrequencyCounter(tagger, channels, sampling_interval, fitting_window, n_values);
            end
            obj@TTIteratorBase(dotNET_frequencyCounter); obj.frequencyCounter = dotNET_frequencyCounter;
        end
        function delete(obj)
            if ~isempty(obj.frequencyCounter)
                obj.frequencyCounter.Dispose();
                obj.frequencyCounter = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.frequencyCounter;
        end
        function ret = getDataObject(obj, event_divider, remove, channels_last_dim)
            narginchk(1, 4);
            if nargin == 1
                ret = TTFrequencyCounterData(obj.frequencyCounter.getDataObject());
            end
            if nargin == 2
                ret = TTFrequencyCounterData(obj.frequencyCounter.getDataObject(event_divider));
            end
            if nargin == 3
                ret = TTFrequencyCounterData(obj.frequencyCounter.getDataObject(event_divider, remove));
            end
            if nargin == 4
                ret = TTFrequencyCounterData(obj.frequencyCounter.getDataObject(event_divider, remove, channels_last_dim));
            end
        end
    end
end