function SignalVec_Random = CreateRandomPulses(obj, M, ka, init_duration, ...
    pi_duration, tau, tau_initial, frequency, frame)
% Creates a sinusoidal random pulse sequence (Channel 2)

    % Generate filtered random binary sequence
    filter = generate_filter_for_random_pulses(M+1, ka);
    U_gaussian = randn(1, M+1);
    V_filtered = conv(U_gaussian, filter, 'same');
    U_binary = sign(V_filtered);

    pi_half_duration = pi_duration / 2;
    current_time = init_duration + tau_initial;

    Times_Random = [];
    Types_Random = {};
    Params_Random = {};

    % Delay after init
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'dc';
    Params_Random{end+1}.Offset = 0;

    % Initial π/2 pulse
    current_time = current_time + pi_half_duration;
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'sine';
    Params_Random{end+1} = struct('Amplitude', 0.5, 'Frequency', frequency, ...
                                  'Phase', 0, 'Frame', frame, 'Offset', 0);

    % τ/2 delay
    current_time = current_time + tau / 2;
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'dc';
    Params_Random{end+1}.Offset = 0;

    % Loop through segments
    for k = 1:M
        current_time = current_time + pi_duration;
        Times_Random(end+1) = current_time;

        if U_binary(k) ~= U_binary(k+1)
            Types_Random{end+1} = 'sine';
            Params_Random{end+1} = struct('Amplitude', 0.5, 'Frequency', frequency, ...
                                          'Phase', 0, 'Frame', frame, 'Offset', 0);
        else
            Types_Random{end+1} = 'dc';
            Params_Random{end+1}.Offset = 0;
        end

        if k < M
            current_time = current_time + tau;
            Times_Random(end+1) = current_time;
            Types_Random{end+1} = 'dc';
            Params_Random{end+1}.Offset = 0;
        end
    end

    % Final τ/2 delay
    current_time = current_time + tau / 2;
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'dc';
    Params_Random{end+1}.Offset = 0;

    % Final π/2 pulse
    current_time = current_time + pi_half_duration;
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'sine';
    Params_Random{end+1} = struct('Amplitude', 0.5, 'Frequency', frequency, ...
                                  'Phase', 0, 'Frame', frame, 'Offset', 0);

    % Final wait
    current_time = current_time + tau / 2;
    Times_Random(end+1) = current_time;
    Types_Random{end+1} = 'dc';
    Params_Random{end+1}.Offset = 0;

    % Generate the waveform
    SignalVec_Random = obj.CreateWaveform(Times_Random, Types_Random, Params_Random, 2);
end
