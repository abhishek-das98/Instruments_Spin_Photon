% This demo measures and plots the count rate over time.
% Choose either Picoharp or TimeTagger below.

AcquisitionDevice = 'TimeTagger'; % 'Picoharp' or 'TimeTagger'
FinalTime = 500; % total measurement time in seconds
Interval = 1; % time between consecutive measurements in seconds
FigureLimitFactor = 1.0001; % scaling factor for the y axis limits

PicoharpChannel = 1; % valid values are 0 or 1

TimeTaggerPhotonChannel = 2;
TimeTaggerPhotonLevel = 0.10;

TimesForPlot = 0:Interval:FinalTime;
PlotStyle = 'b-o';
CountArray = zeros(1, length(TimesForPlot));

if strcmpi(AcquisitionDevice, 'Picoharp')
    Detector = ClassPicoharp.getInstance();
    Detector.connect;
    CounterChannel = PicoharpChannel;
    DetectorName = 'Picoharp';
elseif strcmpi(AcquisitionDevice, 'TimeTagger')
    Detector = ClassTimeTagger.getInstance();
    Detector.connect;
    Detector.SetTriggerLevels(TimeTaggerPhotonChannel, TimeTaggerPhotonLevel);
    CounterChannel = TimeTaggerPhotonChannel;
    DetectorName = 'TimeTagger';
else
    error('AcquisitionDevice must be ''Picoharp'' or ''TimeTagger''.');
end

figure
hold on
xlabel('Time [s]');
ylabel('Count Rate [Hz]');
title(['Count Rate Stability - ' DetectorName]);
set(gca, 'Fontsize', 20)

t = 0;
idx = 1;
tic
while (t <= FinalTime)
    if (idx <= length(TimesForPlot))
        count = Detector.ReadCounter(CounterChannel);

        CountArray(idx) = count;
        MaxCount = max(CountArray(1:idx)) + 1;
        MinCount = min(CountArray(1:idx));

        cla
        plot(TimesForPlot(1:idx), CountArray(1:idx), PlotStyle);
        %ylim([MinCount/FigureLimitFactor MaxCount*FigureLimitFactor]);
        pause(Interval);
    end

    t = toc;
    idx = idx + 1;
end

save TimesForPlot.mat TimesForPlot;
save CountArray.mat CountArray;

Detector.CloseConnection;
