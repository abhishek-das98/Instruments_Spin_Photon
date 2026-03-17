
% Runs a desired experiment, needs to be launched from a user interface
% code

obj.IsRunning=1;
warning('off','all');

%Open Instruments essential for all experiments
InstrumentNames={'AWG','ThorlabsPM','Ophir','EOMInitSupply',AcquisitionMethod};
ConnectToInstruments;

%connect to shutters
clear Shutter1;
if exist('Shutter1')
    InstrumentNames={'Shutter1'};
    ConnectToInstruments;
end
if exist('Shutter2')
    InstrumentNames={'Shutter2'};
    ConnectToInstruments;
end

%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end


% set up right AWG values (delays and right channels)
Channels={Channel1,Channel2,Channel3,Channel4};
InitChannel=find(strcmp(Channels,'Initialization'));
RotateChannel=find(strcmp(Channels,'Rotation'));
TriggerChannel=find(strcmp(Channels,'Trigger'));
RotAOMChannel=find(strcmp(Channels,'Rotation AOM'));
UserDelays=[DelayChannel1,DelayChannel2,DelayChannel3,DelayChannel4];



% connect to AWG with the right number of channels
% if channel 2 is active or not (affects the resolution)
if ~isempty(Channel2)
    obj.AWG.SetSignalNum(2);% two channels + markers
else
    obj.AWG.SetSignalNum(1); % just one channel + markers
end
obj.AWG.SetChannels(Channels,[1:4],UserDelays);

% If there is rotation in the experiment, connect to rotation bias
% corrector
if any(contains(Channels,'Rot')) || any(contains(Channels,'rot'))
    InstrumentNames={'EOMRotSupply'};
    ConnectToInstruments;
end

% If there is diode bias, connect and set it
if DiodeBias>0
    InstrumentNames={'DiodeBiasSupply'};
    ConnectToInstruments;
    obj.Supplies.SetVoltage('DiodeBias',DiodeBias);
end


%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% If the user entered desired initialization/rotation powers and not
% AWG settings, perform calibration to define the necessary AWG settings
% to be used in sequence configurations. Either retrieve calibrated AWG
% values or make a new calibration

%initialization
if strcmp(InitAmplitudeInputMethod,'Power')
    if IsNewInitPowerCalibration
        InitAWGAmplitude=CalibrateLaserPowerAWG(obj,InitialWaveformSequenceTime,InitChannel,0,InitShutterNum,0,1,InitPower);
    else
        InitAWGAmplitude=RetrieveAWGCalibration(obj,InitChannel,0,InitPower);
    end
end


%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

%rotation
if ~isempty(RotateChannel)
if  strcmp(RotationAmplitudeInputMethod,'Power')
    if IsNewRotationPowerCalibration
        RotationAWGAmplitude=CalibrateLaserPowerAWG(obj,1000,RotateChannel,RotationFrequency,RotShutterNum,0,0.4,RotationPower);
    else
        RotationAWGAmplitude=RetrieveAWGCalibration(obj,RotateChannel,RotationFrequency,RotationPower);
    end
  
end
else
    RotationAWGAmplitude=0;
end

%bath polarization initialization & rotation
if  ~(strcmp(AcquisitionMethod,'Spectrometer'))
    if IsBathPolarization
        if strcmp(BathPolarizationAmplitudeInputMethod,'Power')
            if IsNewBathPolarizationPowerCalibration
                BathPolarizationInitAWGAmplitude=CalibrateLaserPowerAWG(obj,1000,InitChannel,0,InitShutterNum,0,1,BathPolarizationInitPower);
                BathPolarizationRotAWGAmplitude=CalibrateLaserPowerAWG(obj,1000,RotateChannel,BathPolarizationRotFrequency,RotShutterNum,0,0.4,BathPolarizationRotPower);
            else
                BathPolarizationInitAWGAmplitude=RetrieveAWGCalibration(obj,InitChannel,0,BathPolarizationInitPower);
                BathPolarizationRotAWGAmplitude=RetrieveAWGCalibration(obj,RotateChannel,BathPolarizationRotFrequency,BathPolarizationRotPower);

            end
        end
    end
end


%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% now configure the specific sequence and the relevant settings
% of the desired experiments according to all input parameters
ConfigureSequence;



%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% Time of initial sequence used for intensity
% calibration and measurement
InitialWaveformSequenceTime=obj.AWG.AWGStep*(obj.AWG.MinPointsPerSeg+200*obj.AWG.Granularity);


% Prepare Readout method
% If readout is from spectrometer
if (strcmp(AcquisitionMethod,'Spectrometer'))
    obj.Spectrometer.SetCenterWavelength(RamanWavelength);
    obj.Spectrometer.set_exposure(1000*AcquisitionTimePerMeasurement);
    obj.Spectrometer.set_frames(1);
    obj.Spectrometer.ExitFront;
    %Define the commands to run for getting the results
    ReadoutSignalCommand='GetResultsSpectrometer(obj,RamanWavelength,PointsForIntegration,IsDarkCounts,InitChannel);';
    % do not need to take dark counts twice, so for reference
    % IsDarkCounts=0
    ReadoutReferenceCommand='GetResultsSpectrometer(obj,RamanWavelength,PointsForIntegration,0,InitChannel);';
    % spectrometer measurements after bath polarization are irrelevant
    BathPolarizationDuration=0;
    
elseif (contains(AcquisitionMethod,'harp'))
    
    obj.TCSPC.SetTimeStop(AcquisitionTimePerMeasurement); % set acquisition time
    obj.TCSPC.SetResolution(BinResolution); %set TCSPC resolution
    
    %if signal is filtered through spectrometer before SPCM
    if (IsSpectrometerFiltered)
        InstrumentNames={'Spectrometer'};
        ConnectToInstruments;
        obj.Spectrometer.ExitSide;
        obj.Spectrometer.SetCenterWavelength(RamanWavelength);
    end
   
    
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
    
  %Define the commands to run for getting the results
    %last parameter is the segment duration, sometimes
    %slightly different from the 1/TCSPC trigger rate
    ReadoutSignalCommand='GetResultsSPCM(obj,AcquisitionTimePerMeasurement,InitDuration,ReadoutDuration,ReadoutPulseStartVec(OrderOfSegments(k),:),TimeResolvedReadoutPulse,DividedPulse,IsDarkCounts,fig4,fig5,SymbolForPlot,SweepVecRandomized(k),UnitForPlot,PlotStyle,CorrectBiasTime,CorrectBiasRange,InitChannel,RotateChannel,ExperimentStartTime+SectionBeforeExperiment,SectionBeforeExperiment,InitDetector,RotDetector,HistogramFinalTime);';
    UnitForPlotRef=[UnitForPlot ', Reference'];
    ReadoutReferenceCommand='GetResultsSPCM(obj,AcquisitionTimePerMeasurement,InitDuration,ReadoutDuration,ReadoutPulseStartVec(OrderOfSegments(k),:),TimeResolvedReadoutPulse,DividedPulse,IsDarkCounts,fig4,fig5,SymbolForPlot,SweepVecRandomized(k),UnitForPlotRef,PlotStyleReference,CorrectBiasTime,CorrectBiasRange,InitChannel,RotateChannel,ExperimentStartTime+SectionBeforeExperiment,SectionBeforeExperiment,InitDetector,RotDetector,HistogramFinalTime);';
else
    error('Please choose a readout method: Spectrometer, Picoharp or Hydraharp');
end


%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% Start preparing for and running the relevant experiment

% Randomize the swept values if required
if IsRandomized
    OrderOfSegments=randperm(length(SweepVecOrdered));
else
    OrderOfSegments=1:length(SweepVecOrdered);
end

SweepVecRandomized=SweepVecOrdered(OrderOfSegments);


%For two phases reference, the numbers of segments are 2*n-1 (because each segment
%has a following segment with an opposite phase)
if IsReference
    if strcmp(ReferenceMeasurementType,'TwoPhases')
        OrderOfSegments=OrderOfSegments*2-1;
    end
end

HistogramFinalTime=obj.AWG.AWGStep*(max(cellfun(@length,SegmentVec{OrderOfSegments(1)}))+1);
SampFreq=obj.AWG.SampFreq;



    
% Zero vectors of final results
SumSignal=zeros(length(Averages),length(SweepVecRandomized));
SumReference=zeros(length(Averages),length(SweepVecRandomized));
SumDarkCounts=zeros(length(Averages),length(SweepVecRandomized));
AverageResult=zeros(length(SweepVecRandomized));



%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% Start preliminary procedures if needed:
%bias correction + initialization and rotation powers
k=1;

if (CorrectBiasRange>0)
    IsCorrectBias=1;
else
    IsCorrectBias=0;
end

if ~exist('IsMeasureInitialization')
    IsMeasureInitialization=0;
end

if ~exist('IsMeasureRotation')
    IsMeasureRotation=0;
end

if ~((any(strcmp(Channels,'Rotation')) || any(strcmp(Channels,'rotation'))))
        IsMeasureRotation=0;
end

% Measure laser powers
% under the conditions of an "initial waveform":
% waveform with "half-run" in the initialization channel
%and cosine in the rotation channel
if (IsCorrectBias) || (IsMeasureInitialization) || (IsMeasureRotation)
[FractionInit,FractionRot]=SetInitialWaveform(obj,HistogramFinalTime,InitChannel,InitAWGAmplitude,RotateChannel,RotationAWGAmplitude(1),RotationFrequency(1),IsRotAOM,RotAOMChannel);
obj.AWG.SetFreq(SampFreq);
if IsCorrectBias
CorrectBias(obj,CorrectBiasRange,[InitChannel,RotateChannel],[InitDetector,RotDetector]);
end

%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

%Measure initialization power

if (IsMeasureInitialization)
fprintf('\nMeasuring Initialization Average Power\n');
MeasuredInitPower= MeasureLaserPower(obj,InitChannel,InitShutterNum)/FractionInit; %factor 2 because the sequence is half run (1/2 the signal is off)
fprintf(['Initialization Average Power: ' num2str(MeasuredInitPower) ' uW\n']);
if ~exist('AdditionToFigName')
    AdditionToFigName='';
end
AdditionToFigName=[AdditionToFigName '_InitPower_' num2str(MeasuredInitPower) 'uW'];
end

%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% if rotation exists, measure rotation power
if (IsMeasureRotation)
    fprintf('\nMeasuring Rotation Average Power\n');
    MeasuredRotationPower= MeasureLaserPower(obj,RotateChannel,RotShutterNum)/FractionRot;
    fprintf(['Rotation Average Power: ' num2str(MeasuredRotationPower) ' uW\n']);
    AdditionToFigName=[AdditionToFigName '_RotationPower_' num2str(MeasuredRotationPower) 'uW'];
end
end

%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

obj.AWG.SetChannels(Channels,[1:4],UserDelays); % if "SetInitialWaveform" changed the channel settings, change them back to the experiment ones



%Prepare for plotting results
FigName=['temp/' datestr(now,"yyyymmdd_hhMMss") '_' ExperimentType '_' ];
PlotColor=['b','r','g','m','k','c']; % Color of the plot b,r,g,y,m,c,k
PlotStyle=[PlotColor(mod(k,length(PlotColor))+1) '.-'];

%figure with averaged results
if Averages>1
    fig1=figure;
    h1=plot(0,PlotStyle,'EraseMode','background','MarkerSize',24);
    xlabel(FigureXLabel);
    if (IsReference) || (contains(AcquisitionMethod,'harp') && (DividedPulse>0) && isnumeric(DividedPulse))
        ylabel('Normalized Contrast');
    else
        ylabel('Fluorescence [counts]');
    end
    title(['Averaged ' ExperimentType]);
    if ~exist('IsCloseFinal') %whether to close the plot after finishing
        IsCloseFinal=0;
    end
end


%start experiment
for AvNum=1:Averages
    
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
    
    SignalArr=[];
    ReferenceArr=[];
    DarkCountsArr=[];
    DarkReferenceCountsArr=[];
    %prepare figures for each average
    %Final results, single average
    fig2=figure;
    h2=plot(0,PlotStyle,'EraseMode','background','MarkerSize',24);
    xlabel(FigureXLabel);
    ylabel('Normalized Contrast');
    if Averages>1
    title([ExperimentType ' , average ' num2str(AvNum)]);
    else 
        title(ExperimentType);
    end
    
    if ~exist('IsCloseSingle') %whether to close the plot after finishing
        IsCloseSingle=0;
    end
    
    
    %raw data single average, plot only if necessary (i.e. if the raw data is different than final one)
   if (IsDarkCounts) || (IsReference) 
    fig3=figure;
    h3 = plot(0,0,'.-',0,0,'.-',0,0,'.-','EraseMode','background','MarkerSize',24);
        if strcmp(ReferenceMeasurementType,'NoRotation')
            legend('With Rotation','No Rotation','Dark Counts');
        elseif strcmp(ReferenceMeasurementType,'TwoPhases')
            legend('First Phase','Second Phase','Dark Counts');
        else
            legend('First','Second','Dark Counts');
        end
    xlabel(FigureXLabel);
    if  (contains(AcquisitionMethod,'harp') && (DividedPulse>0) && isnumeric(DividedPulse))
        ylabel('Normalized Contrast');
    else
        ylabel('Fluorescence [counts]');
    end
    if Averages>1
        title(['Raw ' ExperimentType ' data, average ' num2str(AvNum)]);
    else
        title(['Raw ' ExperimentType ' data']);
    end
   
    if ~exist('IsCloseRaw') %whether to close the plot after finishing
        IsCloseRaw=0;
    end 
end
    % If time-resolvedCreate a plot just for histogram
    if contains(AcquisitionMethod,'harp')
        
        %histogram figure
        fig4=figure;
        h4=plot(0,'EraseMode','background');
        xlabel('Time [ns]');
        ylabel('Fluorescence [counts]');
        if Averages>1
        title(['Histograms for ' ExperimentType ', average ' num2str(AvNum)]);
        else
            title(['Histograms for ' ExperimentType]);
        end
        if KeepHistograms
            hold on
        end
       
    if ~exist('IsCloseHistogram') %whether to close the plot after finishing
        IsCloseHistogram=0;
    end
    end
    
    
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
    
    % figure for showing the results of individual pulses
    if AnalyzeEveryInitPulse
        fig5=figure;
        h5=plot(0,'EraseMode','background');
        xlabel('Free Evolution Time [ns]');
        if (DividedPulse>0) && isnumeric(DividedPulse)
            ylabel('Normalized Contrast');
        else
            ylabel('Fluorescence [counts]');
        end
        title(['Individual Pulse Results for ' ExperimentType ', average' num2str(AvNum)]);
        hold on
        if ~exist('IsCloseAllPulses')
            IsCloseAllPulses=0;
        end
    else
        fig5=[];
    end
   
    
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
    
    % start measurement of the average
    fprintf(['\nStarting measurement, average ' num2str(AvNum)  '\n']);
    
    TimeSinceLastCorrection=tic; %count time for DC bias
    
    for k=1:length(SweepVecRandomized)
        % plot properties
        PlotStyle=[PlotColor(mod(k,length(PlotColor))+1) '.-'];
        PlotStyleReference=[PlotColor(mod(k,length(PlotColor))+1) '--'];
        
        % Run Sequence with the correct randomized segment
        if ~(UploadSegmentsInAdvance) % if we want to upload every segment from scratch to save AWGspace, we should erase all previous segments
            obj.AWG.abort;
            obj.AWG.ClearSegments;
        end
        obj.AWG.RunSegment(SegmentVec{OrderOfSegments(k)});

        
        if CorrectBiasEachMeas && IsCorrectBias
            CorrectBias(obj,CorrectBiasRange,[InitChannel,RotateChannel],[InitDetector,RotDetector]);
        end

        pause(1);
        %Read counts according to previous preset(Spectrometer/SPCM)
        [SignalArr(k),DarkCountsArr(k)]=eval(ReadoutSignalCommand);
        ReferenceArr(k) = 0;
        ResultArr(k)=SignalArr(k);

        
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
        
        if (IsReference) % measure additional reference if needed
   
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end
            if strcmp(ReferenceMeasurementType,'NoRotation')
                obj.AWG.ChannelsOff(RotateChannel);
                [ReferenceArr(k),DarkReferenceCountsArr(k)]=eval(ReadoutReferenceCommand);
                obj.AWG.ChannelsOn(RotateChannel);
            else
                % if the reference is pulse with different phase, its
                % segment index is just the following one (k+1)
                
                if ~(UploadSegmentsInAdvance) % if we want to upload every segment from scratch to save AWGspace, we should erase all previous segments
                    obj.AWG.abort;
                    obj.AWG.ClearSegments;
                end
                
                obj.AWG.RunSegment(SegmentVec{OrderOfSegments(k)+1});
                pause(1);
                [ReferenceArr(k),DarkReferenceCountsArr(k)]=eval(ReadoutReferenceCommand);
            end
            ResultArr(k)=(SignalArr(k)-ReferenceArr(k))/(SignalArr(k)+ReferenceArr(k));
        end
        
   
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end     
        %Plot results
        %first order the randomized results
        [SweepsOrdered,order]=sort(SweepVecRandomized(1:k));
        ResultArrOrdered=ResultArr(order);
        SignalArrOrdered=SignalArr(order);
        ReferenceArrOrdered=ReferenceArr(order);
        DarkCountsArrOrdered=DarkCountsArr(order);
        
        %print results on figure and save figures
        set(h2,'Xdata',SweepsOrdered,'Ydata',ResultArrOrdered);
        
        if (IsDarkCounts) || (IsReference)
        set(h3(1),'Xdata',SweepsOrdered,'Ydata',SignalArrOrdered);
        set(h3(2),'Xdata',SweepsOrdered,'Ydata',ReferenceArrOrdered);
        set(h3(3),'Xdata',SweepsOrdered,'Ydata',DarkCountsArrOrdered);
        end
        
        drawnow;
        savefig(fig2,[FigName '_Average_' num2str(AvNum) '_' AdditionToFigName '_Results.fig']);
        
        if (IsDarkCounts) || (IsReference)
        savefig(fig3,[FigName '_Average_' num2str(AvNum) '_' AdditionToFigName '_Raw.fig']);
        end
        
        if contains(AcquisitionMethod,'harp')
            savefig(fig4,[FigName '_Average_' num2str(AvNum) '_' AdditionToFigName '_Histogram.fig']);
        end
        
        if (AnalyzeEveryInitPulse)
            savefig(fig5,[FigName '_Average_' num2str(AvNum) '_' AdditionToFigName 'AllPulses.fig']);
        end
        
        % If the time has come, correct the bias
        if (toc(TimeSinceLastCorrection)>CorrectBiasTime) && IsCorrectBias
            CorrectBias(obj,CorrectBiasRange,[InitChannel,RotateChannel],[InitDetector,RotDetector]);
            TimeSinceLastCorrection=tic;
        end
    
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end    
    end
    
    %average results
    SumSignal(AvNum,:)=SignalArrOrdered;
    SumReference(AvNum,:)=ReferenceArrOrdered;
    SumDarkCounts(AvNum,:)=DarkCountsArrOrdered;
    if IsReference
        AverageResult=((sum(SumSignal)-sum(SumReference))./(sum(SumSignal)+sum(SumReference)))/Averages;
    else
        AverageResult=sum(SumSignal)/Averages;
    end
    
    % plot and save averaged results
    if Averages>1
    set(h1,'Xdata',SweepsOrdered,'Ydata',AverageResult);
    savefig(fig1,[FigName '_' num2str(AvNum) '_Averages_' AdditionToFigName '.fig']);
    end
    
    save([FigName 'AverageResult.mat'],'AverageResult');
    save([FigName 'SignalMeasurements.mat'],'SumSignal');
    save([FigName 'ReferenceMeasurements.mat'],'SumReference');
    save([FigName 'DarkCountMeasurements.mat'],'SumDarkCounts');
   
%Stop experiment if button pressed
if ~obj.IsRunning
    fprintf('Experiment Stopped\n');
    return;
end

% close figures of experiments if relevant
if exist('fig2') 
    if IsCloseSingle
    close(fig2);
    clear fig2;
    end
end

if exist('fig3') 
    if IsCloseRaw
    close(fig3);
    clear fig3;

    end
end

if exist('fig4') 
    if IsCloseHistogram
    close(fig4);
            clear fig4;
    end
end

if ~isempty('fig5')
    if IsCloseAllPulses
        close(fig5);
        clear fig5;
    end
end
    
    



end


if exist('fig1') 
    if IsCloseFinal
    close(fig1);
    clear fig1;
    end
end

            


if isfield(obj,'TCSPC')
    obj.TCSPC.CloseConnection;
end


%finalize experiment
obj.IsRunning=0;
fprintf('\nExperiment completed\n');

