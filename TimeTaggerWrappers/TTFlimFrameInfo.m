classdef TTFlimFrameInfo < handle
    properties (Access = private)
        flimFrameInfo
    end
    properties (Access = public)
        pixels
        bins
        frame_number
        pixel_position
        valid
    end
    methods (Access = public)
        function obj = TTFlimFrameInfo(dotNET_object)
            obj.flimFrameInfo = dotNET_object;
            obj.pixels = uint32(dotNET_object.pixels);
            obj.bins = uint32(dotNET_object.bins);
            obj.frame_number = int32(dotNET_object.frame_number);
            obj.pixel_position = uint32(dotNET_object.pixel_position);
            obj.valid = logical(dotNET_object.valid);
        end
        function delete(obj)
            if ~isempty(obj.flimFrameInfo)
                obj.flimFrameInfo.Dispose();
                obj.flimFrameInfo = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.flimFrameInfo;
        end
        function ret = getFrameNumber(obj)
            ret = int32(obj.flimFrameInfo.getFrameNumber());
        end
        function ret = isValid(obj)
            ret = logical(obj.flimFrameInfo.isValid());
        end
        function ret = getPixelPosition(obj)
            ret = uint32(obj.flimFrameInfo.getPixelPosition());
        end
        function ret = getHistograms(obj)
            ret = uint32(obj.flimFrameInfo.getHistograms());
        end
        function ret = getIntensities(obj)
            ret = single(obj.flimFrameInfo.getIntensities());
        end
        function ret = getSummedCounts(obj)
            ret = uint64(obj.flimFrameInfo.getSummedCounts());
        end
        function ret = getPixelBegins(obj)
            ret = int64(obj.flimFrameInfo.getPixelBegins());
        end
        function ret = getPixelEnds(obj)
            ret = int64(obj.flimFrameInfo.getPixelEnds());
        end
    end
end