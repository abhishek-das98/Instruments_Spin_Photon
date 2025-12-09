% PM100DHourlyLogExample
% Simple example that logs Thorlabs PM100D power readings every second for one hour
% and plots the results.

% Acquire a singleton instance of the power meter class and connect.
pm100d = ClassThorlabsPM100D.getInstance();
pm100d.connect();

% Configuration
sampleInterval = 1;               % seconds
measurementDuration = 60 * 60;    % one hour in seconds
numSamples = floor(measurementDuration / sampleInterval) + 1;

timeStamps = zeros(numSamples, 1);
powerReadings = zeros(numSamples, 1);
powerReadings_mW = zeros(numSamples, 1);

% Collect data
startTime = tic;
for idx = 1:numSamples
    % Store elapsed time and current power measurement
    timeStamps(idx) = toc(startTime);
    powerReadings(idx) = pm100d.GetPower();
    % Convert to mW for better visualization
    powerReadings_mW(idx) = powerReadings(idx)*1000;

    % Maintain 1 second sampling interval
    pause(sampleInterval);
end

% Close the connection after logging is complete
pm100d.CloseConnection();

% Plot the logged power over time
figure;
plot(timeStamps, powerReadings_mW, '-o');
xlabel('Time (s)');
ylabel('Power (mW)');
title('Thorlabs PM100D Power vs. Time');
grid on;
