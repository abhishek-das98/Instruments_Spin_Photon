classdef TTFlim < TTFlim_internal
    properties (Access = private)
        flim
    end
    methods (Access = public)
        function obj = TTFlim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize)
            TimeTagger.loadAssembly();
            narginchk(7, 12);
            tagger = tagger.getDotNETObject();
            if nargin == 7
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth);
            end
            if nargin == 8
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel);
            end
            if nargin == 9
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel);
            end
            if nargin == 10
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe);
            end
            if nargin == 11
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average);
            end
            if nargin == 12
                dotNET_flim = SwabianInstruments.TimeTagger.Flim(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize);
            end
            obj@TTFlim_internal(dotNET_flim); obj.flim = dotNET_flim;
        end
        function delete(obj)
            if ~isempty(obj.flim)
                obj.flim.Dispose();
                obj.flim = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flim;
        end
        function FrameReadyCallback(obj, frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time)
            obj.flim.FrameReadyCallback(frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time);
        end
    end
end