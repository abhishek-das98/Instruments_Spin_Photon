classdef TTIteratorBase < handle
    properties (Access = private)
        iteratorBase
    end
    methods (Access = public)
        function obj = TTIteratorBase(dotNET_object)
            obj.iteratorBase = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.iteratorBase)
                obj.iteratorBase.Dispose();
                obj.iteratorBase = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.iteratorBase;
        end
        function clear(obj)
            obj.iteratorBase.clear();
        end
        function start(obj)
            obj.iteratorBase.start();
        end
        function startFor(obj, capture_duration, clear)
            narginchk(2, 3);
            if nargin == 2
                obj.iteratorBase.startFor(capture_duration);
            end
            if nargin == 3
                obj.iteratorBase.startFor(capture_duration, clear);
            end
        end
        function stop(obj)
            obj.iteratorBase.stop();
        end
        function abort(obj)
            obj.iteratorBase.abort();
        end
        function ret = isRunning(obj)
            ret = logical(obj.iteratorBase.isRunning());
        end
        function ret = waitUntilFinished(obj, timeout)
            narginchk(1, 2);
            if nargin == 1
                timeout = -1;
            end
            handle = @(timeout) waitUntilFinished(obj.getDotNETObject, timeout);
            ret = TTIteratorBase.timeoutHandler(handle, timeout);
        end
        function ret = getCaptureDuration(obj)
            ret = int64(obj.iteratorBase.getCaptureDuration());
        end
        function ret = getConfiguration(obj)
            ret = char(obj.iteratorBase.getConfiguration());
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