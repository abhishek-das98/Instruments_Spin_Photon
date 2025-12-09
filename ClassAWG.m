classdef (Sealed) ClassAWG <  handle % cannot be inherited
    % Class for operating the keysight AWG
    %   Detailed explanation goes here
    properties (Dependent = true)
        Ch1Mode %extended or internal
        Ch2Mode
        MemDiv % how many channels should divide the memory to
        InstMode % how many channels & is there a marker
        AWGStep % minimum step size
        SampFreq  % Sampling frequency in GHz
        MaxAmp %Maximum output amplitude
        MaxOffset % Maximum channel offset
        MaxPoints
        MinPointsPerSeg
        ContMode
        GateMode
        ChannelDelays
        ChannelNames
        DelayInit
        DelayRot
        DelayTrigger
        DelayRotAOM
        SignalChannels
        TriggerDefaultAmp
        Granularity

        %maximum amplitudes the user can define for rotation and
        %initialization
        MaxAmpForInitialization
        MaxAmpForRotation
    end
    
    properties (Access = private)
        
        InstrObj
        viRscName = 'TCPIP0::localhost::inst0::INSTR';% This may have to be changed for different computers.
        NumberBits=32; %how many bits used for a waveform
        
        ChannelNum=4;
        
        ChannelDelaysPrivate=[0,5,0,0]; % ns, delays required to synchronize between all channels. Change in case of different cabling
        ChannelDelaysDefault=[0,5,0,0];
        ChannelNamesPrivate={'Initialization','Rotation','Trigger','Rotation AOM'};
        
        DelayInitPrivate=0; DelayInitDefault=0;%ns
        DelayRotPrivate=5; DelayRotDefault=5; %ns
        DelayTriggerPrivate=0; DelayTriggerDefault=0; %ns
        TriggerDefaultAmpPrivate=1; %
        DelayRotAOMPrivate=0; DelayRotAOMDefault=0; %AOM for rotation
        
        RotAOMRiseTime=25; %ns, AOM rise time, should open this time before starting rotations
        RotAOMFallTime=20; %ns, AOM fall time, should open this time before starting rotations
        RotAOMAmp=0; %amplitude used for opening the rotation AOM
        
        UploadTimeOut=20;
        Ch1ModePrivate='EXT'; % default - extended memory for channel 1
        Ch2ModePrivate='EXT'; % default - internal memory (not using) channel 2
        InstModePrivate='DCM';
        MemDivPrivate=2; % Default Memory Divider =1 -> All the memory & Freq rate go to channel 1
        SampFreqPrivate=65; % waveform sampling frequency in GHz
        AWGStepPrivate=0.0153846; %minimal change in AWG waveform in ns
        SignalChannelsPrivate=[1,2]; % channels for signal
        SampFreqDefault=65; % waveform sampling frequency in GHz
        MaxAmpPrivate=1; % Is this correct? 1Vpp for single ended, 2Vpp for differential
        MaxOffsetPrivate=1;
        MaxPointsPrivate=2e9; % 2 Giga Samples
        MinPointsPerSegPrivate=1280;
        GranularityPrivate=256;
        
        SegmentLibrary={}; % a library that contains all segments in channel 1st tab and index 2nd tab
        ContModePrivate=1;
        GateModePrivate=0;
        SignalChannelForMarkerUpload=1; % to upload markers, upload segment to channel 1
        Marker1Channel=3;
        Marker2Channel=4;

        %maximum amplitudes the user can define for rotation and
        %initialization
        MaxAmpForInitializationPrivate=1;
        MaxAmpForRotationPrivate=0.4;
        MaxAmpForTrigger=1;
        TriggerOffset=0.2;
    end
    
    
    methods
        
        
        function DelayRotAOM=get.DelayRotAOM(obj)
            DelayRotAOM=obj.DelayRotAOMPrivate;
        end
        
        function TriggerDefaultAmp=get.TriggerDefaultAmp(obj)
            TriggerDefaultAmp=obj.TriggerDefaultAmpPrivate;
        end
        
        function MaxAmpForInitialization=get.MaxAmpForInitialization(obj)
            MaxAmpForInitialization=obj.MaxAmpForInitializationPrivate;
        end
        
        function MaxAmpForRotation=get.MaxAmpForRotation(obj)
            MaxAmpForRotation=obj.MaxAmpForRotationPrivate;
        end
        

        function ChannelNames=get.ChannelNames(obj)
            ChannelNames=obj.ChannelNamesPrivate;
        end
        
        function DelayInit=get.DelayInit(obj)
            DelayInit=obj.DelayInitPrivate;
        end
        function DelayRot=get.DelayRot(obj)
            DelayRot=obj.DelayRotPrivate;
        end
        function DelayTrigger=get.DelayTrigger(obj)
            DelayTrigger=obj.DelayTriggerPrivate;
        end
        function ChannelDelays=get.ChannelDelays(obj)
            ChannelDelays=obj.ChannelDelaysPrivate;
        end
        function SignalChannels=get.SignalChannels(obj)
            SignalChannels=obj.SignalChannelsPrivate;
        end
        function SignalChannelForMarkerUpload=get.SignalChannelForMarkerUpload(obj)
            SignalChannelForMarkerUpload=obj.SignalChannelForMarkerUpload;
        end
        function Marker1Channel=get.Marker1Channel(obj)
            Marker1Channel=obj.Marker1Channel;
        end
        function Marker2Channel=get.Marker2Channel(obj)
            Marker2Channel=obj.Marker2Channel;
        end
        function ContMode=get.ContMode(obj)
            ContMode=obj.ContModePrivate;
        end
        function GateMode=get.GateMode(obj)
            GateMode=obj.GateModePrivate;
        end
        function SampFreq=get.SampFreq(obj)
            SampFreq=obj.SampFreqPrivate;
        end
        
        function SetFreq(obj,NewSampFreq)
            obj.SendCmd(':FREQ:RAST %d', NewSampFreq*10^9);
            obj.SampFreqPrivate=str2num(obj.queryAWG(':FREQ:RAST?'))/10^9; % round the parameters to ones actually stored in the AWG
            obj.AWGStepPrivate=1/obj.SampFreq*obj.MemDiv;
        end
        
        function SetChannelDelays(obj,Channels,Delays)
            for k=1:length(Channels)
                obj.ChannelDelaysPrivate(k)=obj.ChannelDelaysDefault(k)+Delays(k);
            end
        end
        
        
        
        function SetChannels(obj,ChannelNames,ChannelNumbers,UserDelays)
            % adjusts delays from names of channels
            if ~exist('UserDelays')
                UserDelays=zeros(1,length(ChannelNames));
            end
            if ~exist('ChannelNumbers')
                ChannelNumbers=1:1:obj.ChannelNum;
            end
            for k=ChannelNumbers 
                if (strcmp(ChannelNames{k},'Init')) || (strcmp(ChannelNames{k},'Initialization')) || (strcmp(ChannelNames{k},'init')) || (strcmp(ChannelNames{k},'initialization')) || (strcmp(ChannelNames{k},'INIT')) || (strcmp(ChannelNames{k},'INITIALIZATION'))
                    obj.DelayInitPrivate=obj.DelayInitDefault+UserDelays(k);
                    obj.ChannelDelaysPrivate(k)=obj.DelayInit;
                    obj.ChannelNamesPrivate{k}='Initialization';
                    
                    % The signal of initialization is between 0 and
                    % MaxAmpl. To make the best out of it, avoid negative signals,  set offset at
                    % Max/2 and the amplitude is +-Max
                    obj.SetAmpl(k,obj.MaxAmpForInitialization);
                    obj.SetOffset(k,obj.MaxAmpForInitialization/2);

                elseif (strcmp(ChannelNames{k},'rot')) || (strcmp(ChannelNames{k},'ROT')) || (strcmp(ChannelNames{k},'Rot')) || (strcmp(ChannelNames{k},'Rotation')) || (strcmp(ChannelNames{k},'ROTATION')) || (strcmp(ChannelNames{k},'rotation'))
                    obj.DelayRotPrivate=obj.DelayRotDefault+UserDelays(k);
                    obj.ChannelDelaysPrivate(k)=obj.DelayRot;
                    obj.ChannelNamesPrivate{k}='Rotation';
                elseif (strcmp(ChannelNames{k},'trig')) || (strcmp(ChannelNames{k},'TRIG')) || (strcmp(ChannelNames{k},'Trig')) || (strcmp(ChannelNames{k},'trigger')) || (strcmp(ChannelNames{k},'Trigger')) || (strcmp(ChannelNames{k},'TRIGGER'))
                    obj.DelayTriggerPrivate=obj.DelayTriggerDefault+UserDelays(k);
                    obj.ChannelDelaysPrivate(k)=obj.DelayTrigger;
                    obj.ChannelNamesPrivate{k}='Trigger';
                    obj.SetAmpl(k,obj.MaxAmpForTrigger);
                    obj.SetOffset(k,obj.TriggerOffset);
                elseif (strcmp(ChannelNames{k},'rotaom')) || (strcmp(ChannelNames{k},'RotAOM')) || (strcmp(ChannelNames{k},'ROTAOM')) || (strcmp(ChannelNames{k},'ROTATION AOM')) || (strcmp(ChannelNames{k},'rotation aom')) || (strcmp(ChannelNames{k},'Rotation AOM'))
                    obj.DelayRotAOMPrivate=obj.DelayRotAOMDefault+UserDelays(k);
                    obj.ChannelDelaysPrivate(k)=obj.DelayRotAOM;
                    obj.ChannelNamesPrivate{k}='Rotation AOM';
                    obj.SetOffset(k,obj.RotAOMAmp/2);
                elseif ~isempty(ChannelNames{k})
                    obj.userError(['Channel description ' ChannelNames{k} ' not supported, did not update\n']);
                else
                    obj.ChannelDelaysPrivate(k)=0; % if a channel is not activated, don't assign any delay to it

                end
            end
        end
        function AWGstep=get.AWGStep(obj)
            AWGstep=obj.AWGStepPrivate;
        end
        function MaxAmp=get.MaxAmp(obj)
            MaxAmp=obj.MaxAmpPrivate;
        end
        function MaxOffset=get.MaxOffset(obj)
            MaxOffset=obj.MaxOffsetPrivate;
        end
        function MaxPoints=get.MaxPoints(obj)
            MaxPoints=obj.MaxPointsPrivate;
        end
        function Ch1Mode=get.Ch1Mode(obj)
            Ch1Mode=obj.Ch1ModePrivate;
        end
        function Ch2Mode=get.Ch2Mode(obj)
            Ch2Mode=obj.Ch2ModePrivate;
        end
        function MemDiv=get.MemDiv(obj)
            MemDiv=obj.MemDivPrivate;
        end
        function InstMode=get.InstMode(obj)
            InstMode=obj.InstModePrivate;
        end
        function MinPointsPerSeg=get.MinPointsPerSeg(obj)
            MinPointsPerSeg=obj.MinPointsPerSegPrivate;
        end
        
        function Granularity=get.Granularity(obj)
            Granularity=obj.GranularityPrivate;
        end
    end
    
    methods (Access = private)
        function obj = ClassAWG()
        end
    end
    
    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassAWG;
            end
            obj = localObj;
        end
    end
    
    methods
        
        function SendCmd(obj,varargin)
            if length(varargin) > 1
                scpi_str = sprintf(varargin{1}, varargin{2:end}); %may be a problem here
            else
                scpi_str = varargin{1};
            end
            fprintf(obj.InstrObj, scpi_str);
            query(obj.InstrObj, '*OPC?');
        end
        
        function userError(obj,message)
            obj.CloseConnection;
            error(message);
        end
        
        function err=deviceError(obj)
            %%% Read device error.
            err=NaN;
            while err~=0
                errstr=query(obj.InstrObj, ':SYST:ERR?');
                err=str2double(errstr(1:3)); %after letter 3 there is a string that gives a value NAN
                if errstr(1:3)~='0,"'
                    if err<0
                        try
                            obj.CloseConnection;
                        catch err
                            warning(errstr)
                        end
                        obj.CloseConnection();
                        error('Device Status problem: %s\n', errstr);
                    elseif err>0
                        warning('Device Status problem: %s\n', errstr);
                    end
                end
                err=0;
            end
        end
        
        function reset(obj)
            obj.SendCmd('*RST');
        end
        
        function SetSignalNum(obj,SignalNum)
            %number of AWG channels used (1 or 2), excluding markers
            OldMode=obj.InstMode;
            if SignalNum==1
                obj.Ch1ModePrivate='EXT';
                obj.Ch2ModePrivate='NONE';
                obj.InstModePrivate='MARK';
                obj.SignalChannelsPrivate=[1];
                obj.MemDivPrivate=1;
            elseif SignalNum==2
                obj.Ch1ModePrivate='EXT';
                obj.Ch2ModePrivate='EXT';
                obj.InstModePrivate='DCM';
                obj.SignalChannelsPrivate=[1,2];
                obj.MemDivPrivate=2;
            else
                obj.userError(['Does not support total of ' num2str(SignalNum) 'arbitrary signals!\n']);
            end
            
            obj.MemDivPrivate=length(obj.SignalChannels);
            obj.SampFreqPrivate=obj.SampFreqDefault/obj.MemDiv;
            obj.AWGStepPrivate=1/obj.SampFreqPrivate;
            
            obj.SendCmd(':INST:DACM %s',obj.InstMode);
            obj.SendCmd('INST:MEM:EXT:RDIV DIV%d',obj.MemDiv);
            obj.SendCmd(':TRAC1:MMOD %s',obj.Ch1Mode);
            obj.SendCmd(':TRAC2:MMOD %s',obj.Ch2Mode);
            obj.SetFreq(obj.SampFreqDefault);
            if ~strcmp(OldMode,obj.InstMode)
                % if the mode has been changed, it automatically deleted segments,
                % so we need to delete the library as well
                obj.ClearSegments;
            end
            obj.deviceError;
        end
        
        function abort(obj) 
            obj.SendCmd(':ABOR');
        end
        
        function connect(obj,SignalNum) % connect to AWG
            if isempty(obj.InstrObj)
                obj.InstrObj = visa('agilent', obj.viRscName);
            end
            if isempty(obj.InstrObj),
                error('failed to open: %s.', obj.viRscName);
            end
            
            try
                obj.CloseConnection;
            catch
            end
            set(obj.InstrObj,'OutputBufferSize',99999999999999999999999999999999999999999999);
            set(obj.InstrObj, 'TimeOut', obj.UploadTimeOut);%
            
            fopen(obj.InstrObj);
            pause(1);
            idn = query(obj.InstrObj, '*IDN?');
            if ~strfind(idn, 'M8195A');
                error('Instrument not supported');
            else
                fprintf('Instrument IDN: %s\n', idn);
            end
            
            
            % Set modes and sampling frequency for channel 1
            obj.abort;
            obj.ClearSegments;
            if ~exist('SignalNum','var')
                SignalNum=2;
            end
            obj.SetSignalNum(SignalNum);
            for k=SignalNum
            obj.SendCmd(':VOLT%d:AMPL %d',k, obj.MaxAmpPrivate);
            obj.SendCmd(':VOLT%d:AMPL %d',k, obj.MaxAmpPrivate);
            end
            obj.SendCmd(':INIT:CONT %d;GATE %d',obj.ContMode,obj.GateMode);
        end
        
        
        function SegmentNumber=FindSegmentInLibrary(obj,segment)
            %%% Returns the segmentNumber ,
            %%% as found in segmentLibrary{channel}. If not found, returns
            %%% 0
            SegmentNumber = 0;
            k=1;
            while (k<=length(obj.SegmentLibrary) && SegmentNumber==0)
                if (isequal(segment,obj.SegmentLibrary{k}))
                    SegmentNumber=k;
                end
                k=k+1;
            end
        end
        
        
        function newsegment=ModifySegment(obj,segment)
            %            UserDefinedChannels=length(segment);
            UserDefinedChannels=find(~cellfun(@isempty,segment));
            UserMaximumSegmentLength=max(cellfun('length',segment));
            % check that all channels are defined. If not, add zeros
            if length(UserDefinedChannels)<obj.ChannelNum
                %fprintf('Uploading segment warning: not all channels have been defined, added zeros\n');
                for k=UserDefinedChannels(end)+1:obj.ChannelNum
                    segment{k}=zeros(UserMaximumSegmentLength,1);
                end
            end
            for k=UserDefinedChannels
                % check if waveforms in all channels have the same length
                if (length(segment{k})~=UserMaximumSegmentLength) %if segment are not equal, try to compensate, otherwise return an error
                    if (UserMaximumSegmentLength-length(segment{k})==1)
                        %try to add values to the segment
                        if strcmp(obj.ChannelNames{k},'Rotation AOM') % AOM should be open during the last been if was missing in the original sequence
                            segment{k}=[segment{k} obj.RotAOMAmp];
                        else
                            segment{k}=[segment{k} 0]; % Output signals should be 0 during the last been if was missing in the original sequence
                        end
                    else
                    obj.userError('Error: all waveforms have to be the same length, did not run');
                    end
                end
                
                %make sure that segment waveforms are row vectors and single
                if iscolumn(segment{k}) == 0
                    segment{k} = segment{k}';
                end
                segment{k}=single(segment{k});
                
                if length(segment{k})==1 %DC is assumed. MinPointsPerSeg points used to create the waveform
                    segment{k}=segment{k}*ones(1,obj.MinPointsPerSegPrivate);% MinPointsPerSeg is the minimal segment length
                end
                
            end
            newsegment = segment;
        end
        
        function xbinblockwrite(obj,data, BitType, cmd)
            % set debugScpi=1 in MATLAB workspace to log SCPI commands
            if (evalin('base', 'exist(''debugScpi'', ''var'')'))
                fprintf('cmd = %s %s, %d elements\n', cmd, BitType, length(data));
            end
            binblockwrite(obj.InstrObj, data, BitType, cmd);
            fprintf(obj.InstrObj, '');
        end
        
        function AOMWaveform=CreateAOMWaveform(obj,EndTimes,Types,Params,AOMChannel,AOMAmp,AOMRiseTime,AOMFallTime)
            %Creates AOM from waveform based on the segment defined by the
            %user for the light channel, and the AOM specifications and
            %delays
            
            %state of AOM =1 -> open, 0-> closed. Default is open, close it
            %only if possible to close and open before next pulse rise
            
            AOMEndTimes=[];
            AOMTypes={};
            AOMParams={};
            
            FirstOffTime=0;
            
            %Check beginning - if the signal should be on or off
            PreviousSignalState=1; %otherwise pulse is open
            
            for k=1:length(EndTimes)
                %Again - check the status of the signal (open/closed)
                if (strcmp(Types{k},'dc') && Params{k}.Offset==0)
                    CurrentSignalState=0;  %pulse itself is off only if DC with offset zero
                else
                    CurrentSignalState=1; %otherwise pulse is open
                end
                
                % if the Signal pulse was off and turned on now,
                % check the first time and final times without pulse
                % -> Duration withot any pulses -> AOM could be off. If this duration is enough
                % to generate fall and rise of the AOM, start switching it
                % off as soon as the signal is turned off (so the signal is not cut due to fall time)
                % and start switching it on "RiseTime" nanoseconds before
                % the signal is supposed to be on (so the signal is not
                % cut due to rise time)
                
                if (CurrentSignalState==1) && (PreviousSignalState==0) 
                    LastOffTime=EndTimes(k-1);
                    if (LastOffTime-FirstOffTime>AOMRiseTime+AOMFallTime)
                        if FirstOffTime~=0
                            AOMEndTimes=[AOMEndTimes,FirstOffTime];
                            AOMTypes{length(AOMEndTimes)}='dc';
                            AOMParams{length(AOMEndTimes)}.Offset=AOMAmp; %final time of the previous "on" state = zero signal begin
                        end
                        AOMEndTimes=[AOMEndTimes,max(LastOffTime-AOMRiseTime,obj.AWGStep)];
                        AOMTypes{length(AOMEndTimes)}='dc';
                        AOMParams{length(AOMEndTimes)}.Offset=0; %final time of the previous "off" state minus AOM rise time - ensures that the next "on" AOM pulse will include the signal pulse
             
                    end
                    elseif (CurrentSignalState==0) && (PreviousSignalState==1) && (k~=1)
                        FirstOffTime=EndTimes(k-1); %switched from on to off just to start counting the first time without pulse. This will be useful when the pulse will be switch on again (the "if" condition)
                end    
                    PreviousSignalState=CurrentSignalState;
            end
 
            k=length(EndTimes);
            %Last pulse of the sequence, if long enough zero, close final
            %time
            %Again - check the status of the signal (open/closed)
            CurrentSignalState=1;  %pulse itself is off only if DC with offset zero

            if (strcmp(Types{k},'dc') && Params{k}.Offset==0)
                if (PreviousSignalState==0)
                    FirstOffTime=EndTimes(k-1);
                end
                
                if (EndTimes(end)-FirstOffTime>AOMRiseTime+AOMFallTime)
                    
                    AOMEndTimes=[AOMEndTimes,FirstOffTime];
                    AOMTypes{length(AOMEndTimes)}='dc';
                    AOMParams{length(AOMEndTimes)}.Offset=AOMAmp; %final time of the previous "on" state = zero signal begins
             
                    
                    AOMEndTimes=[AOMEndTimes,EndTimes(end)-AOMRiseTime];
                    AOMTypes{length(AOMEndTimes)}='dc';
                    AOMParams{length(AOMEndTimes)}.Offset=0; %final time of the previous "on" state = zero signal begins
                end
                
            end
            
            %Finish the sequence with AOM on, this is the default for the
            %next repetition
            AOMEndTimes=[AOMEndTimes,max(EndTimes(end),obj.AWGStep)];
            AOMTypes{length(AOMEndTimes)}='dc';
            AOMParams{length(AOMEndTimes)}.Offset=AOMAmp;
            
            
            AOMWaveform=obj.CreateWaveform(AOMEndTimes,AOMTypes,AOMParams,AOMChannel);
        
        end
        
        function WriteSegmentToAWG(obj,data,marker,chan,segm_num)
            SegmentLength=length(data);
            if (chan~=obj.SignalChannelForMarkerUpload)
                % there is a weird behavior: to upload a full segment, waveforms should be
                % uploaded separately to channels 1 and 2.
                % After uploading the waveform to channel 1, it
                % automatically uploads something to channel 2 under the
                % same segment. Before uploading the actual channel 2
                % waveform of this segment, the "something" has to be
                % deleted
                obj.SendCmd([':TRAC' num2str(chan) ':DEL ' num2str(segm_num)]);
            end
            obj.SendCmd([':TRAC' num2str(chan) ':DEF ' num2str(segm_num) ',' num2str(SegmentLength)]);
            
            
            %marker = zeros(size(data));
            % scale to DAC values - data is assumed to be -1 ... +1
            dataSize = 'int8';
            data = int8(round(127 * data));
            
            
            
            if (chan==obj.SignalChannelForMarkerUpload)
                dataSize = 'int16';
                data = int16(data);
                data = bitand(data,255);
                data = data + int16(256 * marker);
            end
            use_binblockwrite = 1;
            offset = 0;
            segmentOffset=0;
            while (offset < SegmentLength)
                if (use_binblockwrite)
                    len = min(SegmentLength - offset, 512000);
                    cmd = sprintf(':TRAC%d:DATA %d,%d,', chan, segm_num, offset + segmentOffset);
                    obj.xbinblockwrite(data(1+offset:offset+len), dataSize, cmd);
                else
                    len = min(segm_len - offset, 5120);
                    cmd = sprintf(':TRAC%d:DATA %d,%d', chan, segm_num, offset + segmentOffset);
                    cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                    obj.xfprintf(f, cmd);
                end
                offset = offset + len;
            end
            obj.SendCmd('*WAI');   %Make sure no other commands are exectued until arb is done downloadin
            
            query(obj.InstrObj, '*OPC?'); %make sure the code doesn't continue
            obj.deviceError();
        end
        
        function [Waveform,AOMWaveform] = CreateWaveform(obj,EndTimes,Types,Params,Channel,IsAOM)
            %Create Waveform to be uploaded as a channel of segment to the
            %AWG
            if ~exist('IsAOM')
                IsAOM=0; 
            end
            % add delays to the waveform based on its channel
            DelayAtBeginning=obj.ChannelDelays(Channel);
            ZerosAtEnd=max(obj.ChannelDelays)-DelayAtBeginning;
            
            OriginalEndTimes=EndTimes; %original times without delays, will be needed for AOM (see below)
            OriginalTypes=Types;
            OriginalParams=Params;
            
            if (DelayAtBeginning>0)
                EndTimes=[DelayAtBeginning,EndTimes+DelayAtBeginning];
                Types(2:end+1)=Types;
                Types{1}='dc';
                Params(2:end+1)=Params;
                Params{1}.Offset=0;
            end
            if (ZerosAtEnd>0)
                EndTimes=[EndTimes,ZerosAtEnd+EndTimes(end)];
                Types{end+1}='dc';
                Params{end+1}.Offset=0;
            end
            
            % check length of segment
            if (EndTimes(end)>obj.MaxPoints/obj.SampFreq/obj.MemDiv)
                obj.userError(['Waveform too long for sampling frequency ' num2str(obj.SampFreq) ' GHz, maximum is ' num2str(obj.MaxPoints/obj.SampFreq) ' ns combined for all arbitrary channels\n']);
            elseif (EndTimes(end)<obj.MinPointsPerSeg/obj.SampFreq)
                % if the waveform is too short for a single segment, repeat it several times to
                % form a segment
                repetitions=ceil(obj.MinPointsPerSeg/obj.SampFreq);
                Types=repmat(Types,1,repetitions);
                Params=repmat(Params,1,repetitions);
                EndTimes=kron([0:repetitions-1],EndTimes(end)*ones(1,length(EndTimes)))+repmat(EndTimes,1,repetitions);
            end
            
            
            % adjust the sampling rate so the waveform can follow
            % minwaveform+granularity*n
            
            n=floor((EndTimes(end)*obj.SampFreqDefault/obj.MemDiv-obj.MinPointsPerSeg)/obj.Granularity);
            NewAWGStep=EndTimes(end)/(obj.MinPointsPerSeg+obj.Granularity*n);
            obj.SetFreq(obj.MemDiv/NewAWGStep);
            obj.deviceError;
            EndTimes=round(EndTimes/obj.AWGStep)*obj.AWGStep;
            %This updates the sampling frequency and the step size
            % now build the waveform from functions in the database
            for k=1:length(EndTimes)
                if k==1
                    CurrentTimes=[0:obj.AWGStep:EndTimes(k)-obj.AWGStep];
                    Times=CurrentTimes;
                    Waveform(1:length(Times))=obj.CreateFunction(Times,Types{k},Params{k});
                    LastSectionFinalTime=Times(end);
                else
                    CurrentTimes=[LastSectionFinalTime+obj.AWGStep:obj.AWGStep:EndTimes(k)-obj.AWGStep];
                    Waveform=[Waveform,obj.CreateFunction(CurrentTimes,Types{k},Params{k})];
                    LastSectionFinalTime=CurrentTimes(end);
                    Times=[Times,CurrentTimes];
                end
            end
            
            
            % now create a waveform for turning AOM on and off, if relevant
            
            ChannelName=obj.ChannelNames{Channel};
            if strcmp(ChannelName,'Initialization') && Channel~=obj.Marker1Channel && Channel~=obj.Marker2Channel
                % optimally uses the peak-to-peak AWG definition for
                % initialization
                %the waveform for the AWG is defined from -max/2 to max/2
                %and previously set offset ensures that the actual waveform
                %is from 0 to max
                % This is not the case for channels defined as "markers"
                Waveform=Waveform*2-obj.MaxAmpForInitialization; 
            end
            
            AOMChannel=[];
            if strcmp(ChannelName,'Rotation');
                AOMChannel=find(strcmp(obj.ChannelNames,'Rotation AOM'));
                AOMRiseTime=obj.RotAOMRiseTime;
                AOMFallTime=obj.RotAOMFallTime;
                AOMAmp=obj.RotAOMAmp;
            end
           
            if AOMChannel
              % if the channel of the AOM was defined by user <-> if it is connected to the system  
                if (IsAOM==1) %if the user chose to activate the AOM or leave it open
                 %original (unshifted) times and types of the main waveform
                 %are used, so the delay of the AOM channel is not affected
                 %twice
                    AOMWaveform=obj.CreateAOMWaveform(OriginalEndTimes,OriginalTypes,OriginalParams,AOMChannel,AOMAmp,AOMRiseTime,AOMFallTime);
                else 
                    % if the AOM is on the way, but the user does not want
                    % to activate it, leave it open
                    %AOMParam{1}.Offset=obj.RotAOMAmp;
                    %AOMType{1}='dc';
                    AOMParam{1}.Offset=obj.RotAOMAmp;
                    AOMType{1}='dc';
                    
                    %obj.SetOffset(AOMChannel,obj.RotAOMAmp);
                AOMWaveform=obj.CreateWaveform(OriginalEndTimes(end),AOMType,AOMParam,AOMChannel);
                 
                end
                
            else % No AOM channel defined at all
                AOMWaveform=[];
            end
                            
        end
        
        function Waveform=CreateFunction(obj,Times,Type,Params)
            switch Type
                case {'dc','dc','dc'}
                    Waveform=Params.Offset*ones(1,length(Times));
                case {'cosine','Cosine','COSINE','cos','Cos','COS'}
                    if (strcmp(Params.Frame,'lab') || strcmp(Params.Frame,'LAB') || strcmp(Params.Frame,'Lab'))
                        TimesVecPerFreq=[0:obj.AWGStep:obj.AWGStep*(length(Times)-1)]; % start phase from zero for each pulse
                        Waveform=Params.Offset+Params.Amplitude*cos(2*pi*Params.Frequency*TimesVecPerFreq+Params.Phase);
                    elseif (strcmp(Params.Frame,'rotating') || strcmp(Params.Frame,'Rotating') || strcmp(Params.Frame,'ROTATING'))
                        Waveform=Params.Offset+Params.Amplitude*cos(2*pi*Params.Frequency*Times+Params.Phase); % take into account that the starting time with phase 0 was at t=0
                    else
                        obj.userError('Frame has to be set to either lab or rotating\n');
                    end
                case {'Sine','sine','SINE','sin','SIN','Sin'}
                    Params.Phase=Params.Phase-pi/4; %originally pi/2, here pi/4 because there is a factor of 1/2 in modulation
                    Waveform=obj.CreateFunction(Times,'cos',Params);
                otherwise
                    obj.userError('Function not supported\n');
            end
            
        end
        
        
        function index=UploadSegment(obj,segment)
            obj.abort;
            % checks if segment is ok, modifies
            
               % channel 1 must be defined if channel 2 is defined         
            if isempty(segment{1})
                segment{1}=zeros(1,max(cellfun(@length,segment)));
            end
            
            if length(segment)<obj.Marker1Channel
                segment{obj.Marker1Channel}=[];
            end
            if length(segment)<obj.Marker2Channel
                segment{obj.Marker2Channel}=[];
            end
            if isempty(segment{obj.Marker1Channel})
                segment{obj.Marker1Channel}=zeros(1,length(segment{obj.SignalChannelForMarkerUpload}));
            end
            if isempty(segment{obj.Marker2Channel})
                segment{obj.Marker2Channel}=zeros(1,length(segment{obj.SignalChannelForMarkerUpload}));
            end
            
            segment=obj.ModifySegment(segment);
            % checks if segment already exists
            index=obj.FindSegmentInLibrary(segment);
            % if doesn't exist, upload segment to AWG and to library
            if ~index
                index=length(obj.SegmentLibrary)+1;
                %fprintf('Segment %d:',index,'\n');
                for chan=obj.SignalChannels
                    data=segment{chan};
                    marker=segment{obj.Marker1Channel}+2*segment{obj.Marker2Channel}; % 00=0 -> no, 10=1-> marker 1, 01=2 -> marker2, 11=3-> both markers
                    obj.WriteSegmentToAWG(data,marker,chan,index)
                end
                obj.SegmentLibrary{index} = segment;
            end
            obj.deviceError();
        end
        
        function LoadSegment(obj,segm_num)
            for chan=obj.SignalChannels
                obj.SendCmd([':TRAC' num2str(chan) ':SEL ' num2str(segm_num)]);
            end
            obj.deviceError();
        end
        
        function SetOffset(obj,channel,offset)
            if (offset>obj.MaxOffset)
                display('Offset too large!!')
            elseif (offset<-1*obj.MaxOffset)
                display('Offset too small!!')
            else
                command=['SOUR:VOLT' num2str(channel) ':LEV:IMM:OFFS ' num2str(offset)];
                obj.SendCmd(command);  %Enable output for channel
            end
        end
        function SetAmpl(obj,channel,amp)
            if (amp>obj.MaxAmp)
                display('Amplitude too large!!')
            elseif (amp<0)
                display('Amplitude cannot be negative!!')
            else
                command=['SOUR:VOLT' num2str(channel) ':LEV:IMM:AMPL ' num2str(amp)];
                obj.SendCmd(command);  %Enable output for channel
            end
        end
        function RunSegment(obj,segment)
            %%% Uploads and runs sequence, by loading one segment
            
            SegmentIndex=obj.UploadSegment(segment);
            obj.LoadSegment(SegmentIndex);
            obj.ChannelsOn();
            obj.SendCmd('*WAI');   %Make sure no other commands are exectued until arb is done downloadin
            obj.SendCmd(':FUNC:MODE ARB');
            obj.SendCmd(':INIT:IMM');
            obj.SendCmd('*WAI');   %Make sure no other commands are exectued until arb is done downloadin
            obj.deviceError();
        end
        
        function stopAWG(obj,chn)
            if nargin<2
                chn=1:obj.ChannelNum;
            end
            for channel=chn
                command=['OUTP' num2str(channel) ' OFF'];
                obj.SendCmd(command);  %Disable Output for channel
            end
        end
        
        
        function CloseConnection(obj)
            try
                obj.abort;
                obj.stopAWG();
                obj.ClearSegments;
                fclose(obj.InstrObj);
                flushinput(obj.InstrObj);
                flushoutput(obj.InstrObj);
            catch
            end
            
            fprintf('AWG connection closed\n');
        end
        
        
        function ClearSegments(obj)
            for k=1:obj.ChannelNum
                obj.SendCmd('TRAC%d:DEL:ALL %d',k);
                obj.SegmentLibrary={};
            end
            %fprintf('Old segments cleared\n');
            
        end
    end
    methods
        
        function result=queryAWG(obj,text)
            eval(sprintf('result=query(obj.InstrObj, ''%s'');',text));
        end
        
        function minSegmentLength=findMinSegmentLength(obj,segmentLength)
            % find the minimal required segment length such that
            % minSegmentLength=AWminLength+k*AWstep and minSegmentLength>=segmentLength
            k=ceil((segmentLength-obj.AWminLengthPrivate)/obj.AWstepPrivate); %minimal number of allowed AWG steps
            if k<0
                k=0;
            end
            minSegmentLength=obj.AWminLengthPrivate+k*obj.AWstepPrivate;
        end
        function minSegmentTime=findMinSegmentTime(obj,segmentTime)
            % same as minSegmentLength, but in units of time. Input and
            % autput in \mus!
            f=obj.frequency;
            segmentLength=segmentTime*f;
            minSegmentLength=obj.findMinSegmentLength(segmentLength);
            minSegmentTime=minSegmentLength/f;
        end
        function [steps, timeChange]=durationToSteps(obj,duration)
            f=obj.frequency;
            steps=round(duration*f);
            if steps<0
                error('Negative steps')
            end
            timeChange=steps/f-duration;
            if abs(timeChange)<1e-10;
                timeChange=0;
            end
        end
        function ChannelsOn(obj,chn)
            if nargin<2
                chn=[obj.SignalChannels,obj.Marker1Channel,obj.Marker2Channel];
            end
            for channel=chn
                command=['OUTPUT' num2str(channel) ' ON'];
                obj.SendCmd(command);
            end
        end
        
        function ChannelsOff(obj,chn)
            if nargin<2
                chn=[obj.SignalChannels,obj.Marker1Channel,obj.Marker2Channel];
            end
            for channel=chn
                command=['OUTPUT' num2str(channel) ' OFF'];
                obj.SendCmd(command);
            end
        end
        
        
    end
    
end



