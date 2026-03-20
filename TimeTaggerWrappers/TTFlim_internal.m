classdef TTFlim_internal < TTFlimAbstract_internal
    properties (Access = private)
        flim_internal
    end
    methods (Access = public)
        function obj = TTFlim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize)
            TimeTagger.loadAssembly();
            assert(nargin == 1 || (7 <= nargin && nargin <= 12), 'Incorrect number of arguments')
            if nargin == 1
                assert(isa(tagger, 'SwabianInstruments.TimeTagger.IteratorBase'), 'Argument tagger should be of type SwabianInstruments.TimeTagger.IteratorBase')
                dotNET_flim_internal = tagger;
            else
                tagger = tagger.getDotNETObject();
                if nargin == 7
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth);
                end
                if nargin == 8
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel);
                end
                if nargin == 9
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel);
                end
                if nargin == 10
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe);
                end
                if nargin == 11
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average);
                end
                if nargin == 12
                    dotNET_flim_internal = SwabianInstruments.TimeTagger.Flim_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize);
                end
            end
            obj@TTFlimAbstract_internal(dotNET_flim_internal); obj.flim_internal = dotNET_flim_internal;
        end
        function delete(obj)
            if ~isempty(obj.flim_internal)
                obj.flim_internal.Dispose();
                obj.flim_internal = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flim_internal;
        end
        function ret = getCurrentFrame(obj)
            ret = uint32(obj.flim_internal.getCurrentFrame());
        end
        function ret = getCurrentFrameEx(obj)
            ret = TTFlimFrameInfo(obj.flim_internal.getCurrentFrameEx());
        end
        function ret = getCurrentFrameIntensity(obj)
            ret = single(obj.flim_internal.getCurrentFrameIntensity());
        end
        function ret = getFramesAcquired(obj)
            ret = uint32(obj.flim_internal.getFramesAcquired());
        end
        function ret = getIndex(obj)
            ret = int64(obj.flim_internal.getIndex());
        end
        function ret = getReadyFrame(obj, index)
            if nargin == 1
                ret = uint32(obj.flim_internal.getReadyFrame());
            end
            if nargin == 2
                ret = uint32(obj.flim_internal.getReadyFrame(index));
            end
        end
        function ret = getReadyFrameEx(obj, index)
            if nargin == 1
                ret = TTFlimFrameInfo(obj.flim_internal.getReadyFrameEx());
            end
            if nargin == 2
                ret = TTFlimFrameInfo(obj.flim_internal.getReadyFrameEx(index));
            end
        end
        function ret = getReadyFrameIntensity(obj, index)
            if nargin == 1
                ret = single(obj.flim_internal.getReadyFrameIntensity());
            end
            if nargin == 2
                ret = single(obj.flim_internal.getReadyFrameIntensity(index));
            end
        end
        function ret = getSummedFrames(obj, only_ready_frames, clear_summed)
            if nargin == 1
                ret = uint32(obj.flim_internal.getSummedFrames());
            end
            if nargin == 2
                ret = uint32(obj.flim_internal.getSummedFrames(only_ready_frames));
            end
            if nargin == 3
                ret = uint32(obj.flim_internal.getSummedFrames(only_ready_frames, clear_summed));
            end
        end
        function ret = getSummedFramesEx(obj, only_ready_frames, clear_summed)
            if nargin == 1
                ret = TTFlimFrameInfo(obj.flim_internal.getSummedFramesEx());
            end
            if nargin == 2
                ret = TTFlimFrameInfo(obj.flim_internal.getSummedFramesEx(only_ready_frames));
            end
            if nargin == 3
                ret = TTFlimFrameInfo(obj.flim_internal.getSummedFramesEx(only_ready_frames, clear_summed));
            end
        end
        function ret = getSummedFramesIntensity(obj, only_ready_frames, clear_summed)
            if nargin == 1
                ret = single(obj.flim_internal.getSummedFramesIntensity());
            end
            if nargin == 2
                ret = single(obj.flim_internal.getSummedFramesIntensity(only_ready_frames));
            end
            if nargin == 3
                ret = single(obj.flim_internal.getSummedFramesIntensity(only_ready_frames, clear_summed));
            end
        end
        function initialize(obj)
            obj.flim_internal.initialize();
        end
        function SwigDelegateFlim_internal_0(obj, frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time)
            obj.flim_internal.SwigDelegateFlim_internal_0(frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time);
        end
    end
end