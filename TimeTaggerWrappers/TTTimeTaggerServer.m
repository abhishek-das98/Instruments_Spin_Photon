classdef TTTimeTaggerServer < TTTimeTaggerHardware & TTTimeTaggerSource
    properties (Access = private)
        timeTaggerServer
    end
    methods (Access = public)
        function obj = TTTimeTaggerServer(dotNET_object)
            obj@TTTimeTaggerHardware(dotNET_object); obj@TTTimeTaggerSource(dotNET_object); obj.timeTaggerServer = dotNET_object;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerServer)
                obj.timeTaggerServer.Dispose();
                obj.timeTaggerServer = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerServer;
        end
        function ret = getAddress(obj)
            ret = char(obj.timeTaggerServer.getAddress());
        end
        function ret = getAccessMode(obj)
            ret = TTAccessMode(obj.timeTaggerServer.getAccessMode());
        end
        function ret = getClientChannel(obj, server_channel)
            ret = int32(obj.timeTaggerServer.getClientChannel(server_channel));
        end
    end
end