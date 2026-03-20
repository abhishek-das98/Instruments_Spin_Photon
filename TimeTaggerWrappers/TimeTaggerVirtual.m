classdef TimeTaggerVirtual < TTTimeTaggerBase
    properties (Access = private)
        timeTaggerVirtual
    end
    methods (Access = public)
        function obj = TimeTaggerVirtual(filename, begin, duration)
            TimeTagger.loadAssembly();
            if nargin == 1 && isa(filename, 'SwabianInstruments.TimeTagger.TimeTaggerBase')
                tt = filename; else
                warning(['directly calling the TimeTaggerVirtual class to instantiate a Time Tagger is deprecated !' ...
                    '\n%s To create an instance of TimeTaggerVirtual, please call TimeTagger.createTimeTaggerVirtual() instead.'], '')
                narginchk(0, 3);
                if nargin == 0
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual();
                end
                if nargin == 1
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename);
                end
                if nargin == 2
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename, begin);
                end
                if nargin == 3
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerVirtual(filename, begin, duration);
                end
            end
            obj@TTTimeTaggerBase(tt);
            obj.timeTaggerVirtual = tt;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerVirtual)
                obj.timeTaggerVirtual.Dispose();
                obj.timeTaggerVirtual = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerVirtual;
        end
        function freeTimeTagger(obj)
            if ~isempty(obj.timeTaggerVirtual)
                obj.timeTaggerVirtual.Dispose();
                obj.timeTaggerVirtual = [];
            end
        end
        function ret = run(obj, speed)
            narginchk(1, 2);
            if nargin == 1
                ret = uint64(obj.timeTaggerVirtual.run());
            end
            if nargin == 2
                ret = uint64(obj.timeTaggerVirtual.run(speed));
            end
        end
        function ret = replay(obj, file, begin, duration, queue)
            narginchk(2, 5);
            if nargin == 2
                ret = uint64(obj.timeTaggerVirtual.replay(file));
            end
            if nargin == 3
                ret = uint64(obj.timeTaggerVirtual.replay(file, begin));
            end
            if nargin == 4
                ret = uint64(obj.timeTaggerVirtual.replay(file, begin, duration));
            end
            if nargin == 5
                ret = uint64(obj.timeTaggerVirtual.replay(file, begin, duration, queue));
            end
        end
        function stop(obj)
            obj.timeTaggerVirtual.stop();
        end
        function ret = appendFile(obj, filename, begin, duration, clear)
            narginchk(2, 5);
            if nargin == 2
                ret = uint64(obj.timeTaggerVirtual.appendFile(filename));
            end
            if nargin == 3
                ret = uint64(obj.timeTaggerVirtual.appendFile(filename, begin));
            end
            if nargin == 4
                ret = uint64(obj.timeTaggerVirtual.appendFile(filename, begin, duration));
            end
            if nargin == 5
                ret = uint64(obj.timeTaggerVirtual.appendFile(filename, begin, duration, clear));
            end
        end
        function ret = waitForCompletion(obj, ID, timeout)
            narginchk(1, 3);
            if nargin == 1
                timeout = -1;
                ID = 0;
            end
            if nargin == 2
                ID = 0;
            end
            handle = @(timeout) waitForCompletion(obj.getDotNETObject, ID, timeout);
            ret = TimeTaggerVirtual.timeoutHandler(handle, timeout);
        end
        function ret = waitUntilFinished(obj, ID, timeout)
            narginchk(1, 3);
            if nargin == 1
                timeout = -1;
                ID = 0;
            end
            if nargin == 2
                ID = 0;
            end
            handle = @(timeout) waitUntilFinished(obj.getDotNETObject, ID, timeout);
            ret = TimeTaggerVirtual.timeoutHandler(handle, timeout);
        end
        function setReplaySpeed(obj, speed)
            obj.timeTaggerVirtual.setReplaySpeed(speed);
        end
        function ret = getReplaySpeed(obj)
            ret = double(obj.timeTaggerVirtual.getReplaySpeed());
        end
        function reset(obj)
            obj.timeTaggerVirtual.reset();
        end
        function ret = getChannelList(obj)
            ret = int32(obj.timeTaggerVirtual.getChannelList());
        end
        function setTestSignal(obj, channel, enabled)
            obj.timeTaggerVirtual.setTestSignal(channel, enabled);
        end
        function ret = getTestSignal(obj, channel)
            ret = logical(obj.timeTaggerVirtual.getTestSignal(channel));
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