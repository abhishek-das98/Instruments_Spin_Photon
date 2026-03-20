classdef TTTimeTaggerBase < TTTimeTaggerSource
    properties (Access = private)
        timeTaggerBase
    end
    methods (Access = public)
        function obj = TTTimeTaggerBase(dotNET_object)
            obj@TTTimeTaggerSource(dotNET_object); obj.timeTaggerBase = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerBase)
                obj.timeTaggerBase.Dispose();
                obj.timeTaggerBase = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerBase;
        end
        function setSoftwareClock(obj, input_channel, input_frequency, averaging_periods, wait_until_locked)
            narginchk(2, 5);
            if nargin == 2
                obj.timeTaggerBase.setSoftwareClock(input_channel);
            end
            if nargin == 3
                obj.timeTaggerBase.setSoftwareClock(input_channel, input_frequency);
            end
            if nargin == 4
                obj.timeTaggerBase.setSoftwareClock(input_channel, input_frequency, averaging_periods);
            end
            if nargin == 5
                obj.timeTaggerBase.setSoftwareClock(input_channel, input_frequency, averaging_periods, wait_until_locked);
            end
        end
        function disableSoftwareClock(obj)
            obj.timeTaggerBase.disableSoftwareClock();
        end
        function ret = getSoftwareClockState(obj)
            ret = TTSoftwareClockState(obj.timeTaggerBase.getSoftwareClockState());
        end
        function ret = getFence(obj, alloc_fence)
            narginchk(1, 2);
            if nargin == 1
                ret = uint32(obj.timeTaggerBase.getFence());
            end
            if nargin == 2
                ret = uint32(obj.timeTaggerBase.getFence(alloc_fence));
            end
        end
        function ret = waitForFence(obj, fence, timeout)
            narginchk(2, 3);
            if nargin == 2
                timeout = -1;
            end
            handle = @(timeout) waitForFence(obj.getDotNETObject, fence, timeout);
            ret = TTTimeTaggerBase.timeoutHandler(handle, timeout);
        end
        function ret = sync(obj, timeout)
            narginchk(1, 2);
            if nargin == 1
                timeout = -1;
            end
            fence=obj.getFence();
            ret = obj.waitForFence(fence, timeout);
        end
        function ret = getInvertedChannel(obj, channel)
            ret = int32(obj.timeTaggerBase.getInvertedChannel(channel));
        end
        function ret = isUnusedChannel(obj, channel)
            ret = logical(obj.timeTaggerBase.isUnusedChannel(channel));
        end
        function ret = getConfiguration(obj)
            ret = char(obj.timeTaggerBase.getConfiguration());
        end
        function ret = getRegistrations(obj, channel)
            ret = int32(obj.timeTaggerBase.getRegistrations(channel));
        end
        function ret = isChannelRegistered(obj, channel)
            ret = logical(obj.timeTaggerBase.isChannelRegistered(channel));
        end
        function xtra_setAutoStart(obj, auto_start)
            obj.timeTaggerBase.xtra_setAutoStart(auto_start);
        end
        function ret = xtra_getAutoStart(obj)
            ret = logical(obj.timeTaggerBase.xtra_getAutoStart());
        end
    end
    methods (Static, Access = private)
        function ret = timeoutHandler(callback, timeout)
            if timeout == 0
                ret = callback(timeout);
            end
            max_timeout = 20;
            if timeout < 0
                while ~callback(max_timeout)
                    pause(0);
                end
                ret = true;
            else
                tic;
                while true
                    elapsed_ms = 1000 * toc;
                    remaining_timeout = max(0, min(max_timeout, timeout - elapsed_ms));
                    if callback(remaining_timeout)
                        ret = true;
                        return;
                    end
                    if remaining_timeout == 0
                        ret = false;
                        return;
                    end
                    pause(0);
                end
            end
        end
    end
end