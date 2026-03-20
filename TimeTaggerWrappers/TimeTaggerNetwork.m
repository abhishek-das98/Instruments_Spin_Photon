classdef TimeTaggerNetwork < TTTimeTaggerBase & TTTimeTaggerHardware
    properties (Access = private)
        timeTaggerNetwork
    end
    methods (Static)
        function ret = getTimeTaggerServerInfo(address)
            TimeTagger.loadAssembly();
            narginchk(0, 1);
            if nargin == 0
                ret = char(SwabianInstruments.TimeTagger.TT.getTimeTaggerServerInfo());
            end
            if nargin == 1
                ret = char(SwabianInstruments.TimeTagger.TT.getTimeTaggerServerInfo(address));
            end
        end
        function ret = scanTimeTaggerServers()
            TimeTagger.loadAssembly();
            ret = cell(SwabianInstruments.TimeTagger.TT.scanTimeTaggerServers());
        end
    end
    methods (Access = public)
        function obj = TimeTaggerNetwork(address)
            TimeTagger.loadAssembly();
            if nargin == 1 && isa(address, 'SwabianInstruments.TimeTagger.TimeTaggerBase')
                tt = address; else
                warning(['directly calling the TimeTaggerNetwork class to instantiate a Time Tagger is deprecated !' ...
                    '\n%s To create an instance of TimeTaggerNetwork, please call TimeTagger.createTimeTaggerNetwork() instead.'], '')
                narginchk(0, 1);
                if nargin == 0
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerNetwork();
                end
                if nargin == 1
                    tt = SwabianInstruments.TimeTagger.TT.createTimeTaggerNetwork(address);
                end
            end
            obj@TTTimeTaggerBase(tt);
            obj@TTTimeTaggerHardware(tt);
            obj.timeTaggerNetwork = tt;
        end
        function delete(obj)
            if ~isempty(obj.timeTaggerNetwork)
                obj.timeTaggerNetwork.Dispose();
                obj.timeTaggerNetwork = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.timeTaggerNetwork;
        end
        function freeTimeTagger(obj)
            if ~isempty(obj.timeTaggerNetwork)
                obj.timeTaggerNetwork.Dispose();
                obj.timeTaggerNetwork = [];
            end
        end
        function ret = isConnected(obj)
            ret = logical(obj.timeTaggerNetwork.isConnected());
        end
        function setDelayClient(obj, channel, time)
            obj.timeTaggerNetwork.setDelayClient(channel, time);
        end
        function ret = getDelayClient(obj, channel)
            ret = int64(obj.timeTaggerNetwork.getDelayClient(channel));
        end
        function ret = getOverflowsClient(obj)
            ret = int64(obj.timeTaggerNetwork.getOverflowsClient());
        end
        function ret = getOverflowsAndClearClient(obj)
            ret = int64(obj.timeTaggerNetwork.getOverflowsAndClearClient());
        end
        function clearOverflowsClient(obj)
            obj.timeTaggerNetwork.clearOverflowsClient();
        end
        function ret = getServer(obj, ip_address)
            ret = TTTimeTaggerServer(obj.timeTaggerNetwork.getServer(ip_address));
        end
        function ret = getServers(obj)
            ret = TTTimeTaggerServer(obj.timeTaggerNetwork.getServers());
        end
    end
end