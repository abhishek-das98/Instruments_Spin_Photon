% Magnet ramp with real (date-time) timestamps using ClassMagnetNew
clc; clear; close all;

mag = ClassMagnetNew.getInstance();

% ---------------- User settings ----------------
ULIM_T = 5.0;        % upper limit in Tesla
LLIM_T = -5.0;       % lower limit in Tesla (set to 0.0 if your system is unipolar)

dt_s  = 120;         % sampling period (seconds)
tMax  = minutes(35); % safety timeout for the ramp-to-ULIM logging
tol_T = 0.005;       % tolerance for "reached target" (Tesla)

heater_settle_s = 5; % adjust if your heater needs longer

hold_at_ulim = minutes(2);  % <-- NEW: hold at upper limit
hold_at_zero = minutes(1);  % <-- NEW: hold at zero before heater off
% ----------------------------------------------

t_dt = datetime.empty(0,1);  % real timestamps
B_T  = [];                   % field samples (Tesla)

try
    % Connect
    mag.Connect();

    % Heater ON
    fprintf('Turning persistent heater ON...\n');
    mag.HeaterOn();
    pause(heater_settle_s);

    % Set limits
    fprintf('Setting limits: LLIM = %.3f T, ULIM = %.3f T\n', LLIM_T, ULIM_T);
    mag.SetLowerLimit(LLIM_T);
    mag.SetUpperLimit(ULIM_T);

    % Start ramp to upper limit (slow, i.e., not FAST)
    fprintf('Starting slow sweep to ULIM...\n');
    mag.GoToUpperField();

    % Log field vs real time until near ULIM (or timeout)
    t_start = datetime('now');

    while true
        tNow = datetime('now');
        Bnow = mag.ReadField();

        t_dt(end+1,1) = tNow; %#ok<SAGROW>
        B_T(end+1,1)  = Bnow; %#ok<SAGROW>

        % Occasional console update
        if mod(numel(B_T), 10) == 0
            fprintf('%s | B = %7.4f T | status: %s\n', ...
                datestr(tNow,'yyyy-mm-dd HH:MM:SS'), Bnow, mag.ReadSweepStatus());
        end

        % Stop conditions
        if abs(Bnow - ULIM_T) <= tol_T
            fprintf('Reached ULIM within tolerance at %s (B = %.4f T)\n', ...
                datestr(tNow,'yyyy-mm-dd HH:MM:SS'), Bnow);
            break;
        end

        if (tNow - t_start) >= tMax
            warning('Timed out before reaching ULIM. Last B = %.4f T', Bnow);
            break;
        end

        pause(dt_s);
    end

    % NEW: Hold at ULIM for 2 minutes
    fprintf('Holding at ULIM for %.1f minutes...\n', minutes(hold_at_ulim));
    pause(seconds(hold_at_ulim));

    % Plot: magnetic field vs real date-time
    figure;
    plot(t_dt, B_T, '-o');
    grid on;
    xlabel('Time');
    ylabel('Magnetic Field B (T)');
    title('Magnet Ramp to Upper Limit');

    ax = gca;
    ax.XAxis.TickLabelFormat = 'yyyy-MM-dd HH:mm:ss';
    xtickangle(30);

    % Sweep back to zero (slow)
    fprintf('Sweeping field to zero...\n');
    mag.Zero();

    % Wait until close to zero (optional but nice)
    while true
        Bnow = mag.ReadField();
        if abs(Bnow) <= tol_T
            fprintf('Field is near zero (B = %.4f T)\n', Bnow);
            break;
        end
        pause(0.5);
    end

    % NEW: Hold at zero for 1 minute, then heater OFF
    fprintf('Holding at zero for %.1f minutes...\n', minutes(hold_at_zero));
    pause(seconds(hold_at_zero));

    fprintf('Turning persistent heater OFF...\n');
    mag.HeaterOff();

    fprintf('Done.\n');

catch ME
    fprintf(2, 'ERROR: %s\n', ME.message);
end

% Always close the connection
try
    mag.CloseConnection();
catch
end

% ---------------- Save data to Excel ----------------
dataTable = table(t_dt, B_T, ...
    'VariableNames', {'Timestamp', 'MagneticField_T'});

outFile = ['MagnetRamp_' datestr(datetime('now'),'yyyymmdd_HHMMSS') '.xlsx'];

writetable(dataTable, outFile);

fprintf('Data saved to %s\n', outFile);
% ---------------------------------------------------
