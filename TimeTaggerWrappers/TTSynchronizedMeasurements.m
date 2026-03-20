classdef TTSynchronizedMeasurements < handle
    properties (Access = private)
        synchronizedMeasurements
    end
    methods (Access = public)
        function obj = TTSynchronizedMeasurements(tagger)
            TimeTagger.loadAssembly();
            tagger = tagger.getDotNETObject();
            dotNET_synchronizedMeasurements = SwabianInstruments.TimeTagger.SynchronizedMeasurements(tagger);
            obj.synchronizedMeasurements = dotNET_synchronizedMeasurements;
        end
        function delete(obj)
            if ~isempty(obj.synchronizedMeasurements)
                obj.synchronizedMeasurements.Dispose();
                obj.synchronizedMeasurements = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.synchronizedMeasurements;
        end
        function ret = getTagger(obj)
            ret = TTTimeTaggerBase(obj.synchronizedMeasurements.getTagger());
        end
        function start(obj)
            obj.synchronizedMeasurements.start();
        end
        function startFor(obj, capture_duration, clear)
            narginchk(2, 3);
            if nargin == 2
                obj.synchronizedMeasurements.startFor(capture_duration);
            end
            if nargin == 3
                obj.synchronizedMeasurements.startFor(capture_duration, clear);
            end
        end
        function stop(obj)
            obj.synchronizedMeasurements.stop();
        end
        function clear(obj)
            obj.synchronizedMeasurements.clear();
        end
        function ret = waitUntilFinished(obj, timeout)
            narginchk(1, 2);
            if nargin == 1
                timeout = -1;
            end
            handle = @(timeout) waitUntilFinished(obj.getDotNETObject, timeout);
            ret = TTSynchronizedMeasurements.timeoutHandler(handle, timeout);
        end
        function ret = isRunning(obj)
            ret = logical(obj.synchronizedMeasurements.isRunning());
        end
        function registerMeasurement(obj, measurement)
            measurement = measurement.getDotNETObject();
            obj.synchronizedMeasurements.registerMeasurement(measurement);
        end
        function unregisterMeasurement(obj, measurement)
            measurement = measurement.getDotNETObject();
            obj.synchronizedMeasurements.unregisterMeasurement(measurement);
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