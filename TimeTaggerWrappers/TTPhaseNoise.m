classdef TTPhaseNoise < TTIteratorBase
    properties (Access = private)
        phaseNoise
    end
    methods (Access = public)
        function obj = TTPhaseNoise(tagger, channel, samples_per_octave)
            TimeTagger.loadAssembly();
            narginchk(2, 3);
            tagger = tagger.getDotNETObject();
            if nargin == 2
                dotNET_phaseNoise = SwabianInstruments.TimeTagger.PhaseNoise(tagger, channel);
            end
            if nargin == 3
                dotNET_phaseNoise = SwabianInstruments.TimeTagger.PhaseNoise(tagger, channel, samples_per_octave);
            end
            obj@TTIteratorBase(dotNET_phaseNoise); obj.phaseNoise = dotNET_phaseNoise;
        end
        function delete(obj)
            if ~isempty(obj.phaseNoise)
                obj.phaseNoise.Dispose();
                obj.phaseNoise = [];
            end
        end
        function ret = getDotNETObject(obj)
            ret = obj.phaseNoise;
        end
        function ret = getDataObject(obj)
            ret = TTPhaseNoiseData(obj.phaseNoise.getDataObject());
        end
    end
end