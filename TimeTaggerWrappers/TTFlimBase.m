classdef TTFlimBase < TTFlimBase_internal
    properties (Access = private)
        flimBase
    end
    methods (Access = public)
        function obj = TTFlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize)
            TimeTagger.loadAssembly();
            narginchk(7, 12);
            tagger = tagger.getDotNETObject();
            if nargin == 7
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth);
            end
            if nargin == 8
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel);
            end
            if nargin == 9
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel);
            end
            if nargin == 10
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe);
            end
            if nargin == 11
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average);
            end
            if nargin == 12
                dotNET_flimBase = SwabianInstruments.TimeTagger.FlimBase(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize);
            end
            obj@TTFlimBase_internal(dotNET_flimBase); obj.flimBase = dotNET_flimBase;
        end
        function delete(obj)
            if ~isempty(obj.flimBase)
                obj.flimBase.Dispose();
                obj.flimBase = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flimBase;
        end
        function FrameReadyCallback(obj, frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time)
            obj.flimBase.FrameReadyCallback(frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time);
        end
    end
end