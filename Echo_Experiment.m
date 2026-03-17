% User interface code for running an experiment
% Just set the relevant parameters, and the last line RunExperiment will do
% the job
% please do not change the names of the variables!


% User defined parameters
ExperimentType='Echo';

%Assign a name to the measurement (number of sample/structure/dot/etc...)
ExperimentName='FirstTry'; 

%AWG Channels
Channel1='Initialization';
Channel2='Rotation';
Channel3='Trigger';
Channel4='';

% Experiment settings

%Initialization duration and AWG amplitude
InitDuration=5;% in ns
InitAWGAmplitude=1;

%Rotation settings
%Rotation duration and AWG amplitude
RotationFrequency=[9.5]; % Rotation frequency
Frame='rotating'; % frame='lab' or 'rotating' 
PiHalfDuration=5;
PiHalfAWGAmplitude=0.4;
PhaseFirstPulse=0; % phases of initial and final pi/2 pulses
PhaseSecondPulse=0;

%pi pulses
PiDuration=12;
PiAWGAmplitude=0.4;
%phase of pi pulses, should be perpendicular to pi/2 pulses for best
%performance
PiPulsePhase=pi/2; 

% Full Spin Interrogation time sweep in the experiment
% note that it must be longer than rotation time and potential AOM delays
SpinInterrogationTimeVec=[20:10:50];

%EOM bias correction settings
CorrectBiasRange=0; %range to correct bias before resuming experiment, in volts
CorrectBiasTime=60*10; %Time between two EOM bias corrections, in seconds

% Diode Bias voltage (set 0 if irrelevant)
DiodeBias=0.5;

% Readout settings
SequenceRepetitions=5; %how many times to repeat the sequence consequtively (bath only polarized one time)
Averages=1; %how many times the whole experiment is repeated
AcquisitionTimePerMeasurement=3; % in s
IsRandomized=1; %measurements in chronological order or random order
IsDarkCounts=1; %Add a measurement of dark counts (no initialization with rotation) to reduce dark counts 
IsReference=1; % Include additional measurement for normalization purposes (this case: with initialization, without rotation)

if (IsReference)
    PhaseSecondPulseReference=pi;
end

% If the code uploads all segments in advance before starting
% pro: faster and smoother experiments 
% con: takes a lot of spcae, cannot work when the experiments are long
UploadSegmentsInAdvance=1;

%Possible Readout Methods: 'Spectrometer' / 'Picoharp' / 'Hydraharp'
AcquisitionMethod='Hydraharp'; %

if (strcmp(AcquisitionMethod,'Spectrometer'))

    %assign values only if readout is from spectrometer
    RamanWavelength=930; % Wavelength the measure
    PointsForIntegration=3; %how many points to integrate around the center wavelength

elseif (contains(AcquisitionMethod,'harp'))
    %assign values only if readout is from picoharp/hydraharp
    
    BinResolution=512; % resolution of bins in ps
    ReadoutDuration=5; %Duration of photon collection within an initialization pulse
    KeepHistograms=1; % if keep old histograms or erase them
    
    %What is the number of initialization pulse to be analyzed. 
    % If not specified, sums all of them
    TimeResolvedReadoutPulse=2;
    
    %If the measurement pulse should be divided by another pulse,
    %here is the divided pulse number (0 for none)
    DividedPulse=1;
    
    IsSpectrometerFiltered=1; % Does the signal go directly to TCSPC or filtered through spectrometer 
    if (IsSpectrometerFiltered)
        RamanWavelengthSlitSide=930;
    end
        
    % If bath polarization is necessary, define duration, rotation frequency,
    %and initialization and rotation amplitudes
    
    IsBathPolarization=1;
    if IsBathPolarization
        BathPolarizationDuration=1;
        BathPolarizationInitAWGAmplitude=0.1;
        BathPolarizationRotFrequency=1;
        BathPolarizationRotAWGAmplitude=0.4;
    end
    
    
else
    error('Please choose acquisition method: Spectrometer, Picoharp or Hydraharp');
end

% Launch the experiment
RunExperiment;