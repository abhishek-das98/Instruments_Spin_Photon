classdef TTFrequencyCounterData < handle
    properties (Access = private)
        frequencyCounterData
    end
    properties (Access = public)
        size
        overflow_samples
        align_to_reference
        sampling_interval
        sample_offset
        channels_last_dim
    end
    methods (Access = public)
        function obj = TTFrequencyCounterData(dotNET_object)
            obj.frequencyCounterData = dotNET_object;
            obj.size = uint32(dotNET_object.size);
            obj.overflow_samples = int64(dotNET_object.overflow_samples);
            obj.align_to_reference = logical(dotNET_object.align_to_reference);
            obj.sampling_interval = int64(dotNET_object.sampling_interval);
            obj.sample_offset = int64(dotNET_object.sample_offset);
            obj.channels_last_dim = logical(dotNET_object.channels_last_dim);
        end
        function delete(obj)
            if ~isempty(obj.frequencyCounterData)
                obj.frequencyCounterData.Dispose();
                obj.frequencyCounterData = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.frequencyCounterData;
        end
        function ret = getIndex(obj)
            ret = int64(obj.frequencyCounterData.getIndex());
        end
        function ret = getTime(obj)
            ret = int64(obj.frequencyCounterData.getTime());
        end
        function ret = getPeriodsCount(obj)
            ret = int64(obj.frequencyCounterData.getPeriodsCount());
        end
        function ret = getPeriodsFraction(obj)
            ret = double(obj.frequencyCounterData.getPeriodsFraction());
        end
        function ret = getPhase(obj, reference_frequency)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.frequencyCounterData.getPhase());
            end
            if nargin == 2
                ret = double(obj.frequencyCounterData.getPhase(reference_frequency));
            end
        end
        function ret = getFrequency(obj, time_scale)
            narginchk(1, 2);
            if nargin == 1
                ret = double(obj.frequencyCounterData.getFrequency());
            end
            if nargin == 2
                ret = double(obj.frequencyCounterData.getFrequency(time_scale));
            end
        end
        function ret = getFrequencyInstantaneous(obj)
            ret = double(obj.frequencyCounterData.getFrequencyInstantaneous());
        end
        function ret = getOverflowMask(obj)
            ret = int8(obj.frequencyCounterData.getOverflowMask());
        end
    end
end