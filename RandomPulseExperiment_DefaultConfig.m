function cfg = RandomPulseExperiment_DefaultConfig()
% RandomPulseExperiment_DefaultConfig
% Small, editable defaults for code-only random-pulse runs.
%
% Start with:
%   cfg = RandomPulseExperiment_DefaultConfig();
%   cfg.DryRun = true;      % no hardware calls, safe for code checks
%   results = RandomPulseExperiment_Code(cfg);

    cfg = struct();

    % --- Safety / development mode ---
    cfg.DryRun = true;  % true: build waveforms only, false: touch instruments

    % --- AWG channel map (matches your ClassAWG defaults) ---
    cfg.Channels = {'Initialization', 'Rotation', 'Trigger', ''};
    cfg.UserDelaysNs = [0, 0, 0, 0];

    % --- Random pulse sequence parameters ---
    cfg.Random.M = 24;                 % number of pi slots in the random train
    cfg.Random.ka = pi / 8;            % filter control parameter
    cfg.Random.InitDurationNs = 10;    % initialization duration before random block
    cfg.Random.PiDurationNs = 8;       % pi pulse duration in random block
    cfg.Random.TauNs = 20;             % interpulse free-evolution time
    cfg.Random.TauInitialNs = 5;       % delay between init and first pi/2
    cfg.Random.FrequencyGHz = 9.5;     % rotation drive frequency in GHz
    cfg.Random.Frame = 'rotating';     % 'rotating' or 'lab'

    % --- Initialization / trigger amplitudes ---
    cfg.InitAmplitude = 1.0;           % normalized AWG amplitude for init channel
    cfg.TriggerAmplitude = 1.0;        % marker-like digital trigger level (0/1)


    % --- Optional bath polarization block (mirrors Echo_Experiment style) ---
    cfg.BathPolarization.Enable = false;
    cfg.BathPolarization.DurationNs = 1000;      % duration before random sequence
    cfg.BathPolarization.InitAmplitude = 0.1;    % initialization channel level
    cfg.BathPolarization.RotAmplitude = 0.4;     % rotation channel sine amplitude
    cfg.BathPolarization.RotFrequencyGHz = 1.0;  % bath-polarization rotation frequency
    cfg.BathPolarization.Frame = 'rotating';

    % --- Acquisition options (optional first-step integration) ---
    cfg.Acquisition.Mode = 'none';     % 'none' | 'picoharp' | 'spectrometer'

    % PicoHarp parameters (used only when Mode = 'picoharp')
    cfg.PicoHarp.ResolutionPs = 512;
    cfg.PicoHarp.AcquisitionTimeS = 2;

    % LightField / spectrometer parameters (used only when Mode = 'spectrometer')
    cfg.Spectrometer.Visible = true;
    cfg.Spectrometer.ExperimentName = "Experiment_Spectrometer_Mode";
    cfg.Spectrometer.ExposureMs = 100;
    cfg.Spectrometer.Frames = 1;
    cfg.Spectrometer.CenterWavelengthNm = 930;
    cfg.Spectrometer.ExitPort = "side";  % "front" or "side"

    % --- Optional power supply hook ---
    cfg.Supply.Enable = false;
    cfg.Supply.Name = 'SinglePowerSupply';
    cfg.Supply.Voltage = 0.0;
    cfg.Supply.Channel = 1;            % used only for triple supply
end
