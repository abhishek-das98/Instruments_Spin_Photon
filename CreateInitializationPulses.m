function SignalVec_Init = CreateInitializationPulses(obj, init_duration, final_time)
% Creates initialization waveform (Channel 1)
% final_time should match the end of the random pulse sequence

    Times_Init = [init_duration, final_time];
    Types_Init = {'dc', 'dc'};
    Params_Init = {struct('Offset', 1), struct('Offset', 0.5)};  % Customize offsets if needed

    SignalVec_Init = obj.CreateWaveform(Times_Init, Types_Init, Params_Init, 1);
end
