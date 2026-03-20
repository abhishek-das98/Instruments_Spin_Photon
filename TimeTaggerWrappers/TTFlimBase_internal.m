classdef TTFlimBase_internal < TTFlimAbstract_internal
    properties (Access = private)
        flimBase_internal
    end
    methods (Access = public)
        function obj = TTFlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize)
            TimeTagger.loadAssembly();
            assert(nargin == 1 || (7 <= nargin && nargin <= 12), 'Incorrect number of arguments')
            if nargin == 1
                assert(isa(tagger, 'SwabianInstruments.TimeTagger.IteratorBase'), 'Argument tagger should be of type SwabianInstruments.TimeTagger.IteratorBase')
                dotNET_flimBase_internal = tagger;
            else
                tagger = tagger.getDotNETObject();
                if nargin == 7
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth);
                end
                if nargin == 8
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel);
                end
                if nargin == 9
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel);
                end
                if nargin == 10
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe);
                end
                if nargin == 11
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average);
                end
                if nargin == 12
                    dotNET_flimBase_internal = SwabianInstruments.TimeTagger.FlimBase_internal(tagger, start_channel, click_channel, pixel_begin_channel, n_pixels, n_bins, binwidth, pixel_end_channel, frame_begin_channel, finish_after_outputframe, n_frame_average, pre_initialize);
                end
            end
            obj@TTFlimAbstract_internal(dotNET_flimBase_internal); obj.flimBase_internal = dotNET_flimBase_internal;
        end
        function delete(obj)
            if ~isempty(obj.flimBase_internal)
                obj.flimBase_internal.Dispose();
                obj.flimBase_internal = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flimBase_internal;
        end
        function initialize(obj)
            obj.flimBase_internal.initialize();
        end
        function SwigDelegateFlimBase_internal_0(obj, frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time)
            obj.flimBase_internal.SwigDelegateFlimBase_internal_0(frame_number, data, pixel_begin_times, pixel_end_times, frame_begin_time, frame_end_time);
        end
    end
end