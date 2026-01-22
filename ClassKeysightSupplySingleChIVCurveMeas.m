clc; clear; close all;

Vset_pos = 0.1:0.1:3.2;    % first sweep: positive polaity
Vset_neg = 0.1:0.1:1.4;    % after sweeping polarity (stored as negative)

readDelay_s = 2;    % Settling time of the supply for the measurement

% Prelocate
Vmeas_pos = nan(size(Vset_pos));
Imeas_pos = nan(size(Vset_pos));

Vmeas_neg = nan(size(Vset_neg));
Imeas_neg = nan(size(Vset_neg));

% Connect to the supply
ps = ClassKeysightSupply.getInstance();

try
    ps.connect('SinglePowerSupply');

    ps.setVoltage(0);
    ps.powerOn();

    fprintf('\n--- Sweep 1: +V from 0.1 to 3.2 V ---\n');
    for k = 1:numel(Vset_pos)
        Vtarget = Vset_pos(k);
        ps.setVoltage(Vtarget);

        Vmeas_pos(k) = ps.readVoltage();
        Imeas_pos(k) = 1e3 * ps.readCurrent();    % Reads current in mA

        pause(readDelay_s);

    end
    ps.setVoltage(0);
    fprintf('\nReached 3.2 V.\n');
    fprintf('Now PLEASE swap the polarity of the voltage connection.\n');
    input('Press Enter when you have swapped the polarity and are ready to continue...', 's');

    % Sweep 2
    fprintf('\n Sweep 2: (Negative polarity) from 0.1 to 1.4 V \n');
    for k = 1:numel(Vset_neg)
        Vtarget = Vset_neg(k);
        ps.setVoltage(Vtarget);
        
        Vmeas_neg(k) = -abs(ps.readVoltage());
        Imeas_neg(k) = 1e3 * ps.readCurrent();    % Reads current in mA

        pause(readDelay_s);

    end

    ps.setVoltage(0);
    ps.powerOff();
    ps.disconnect();

catch ME
    try
        ps.setVoltage(0);
        ps.powerOff();
        ps.disconnect();
    catch

    end
    rethrow(ME);
end

% Combine and sort
Vset_all_raw  = [Vset_pos,   -Vset_neg];  % set values (second sweep stored negative)
Vmeas_all_raw = [Vmeas_pos,   Vmeas_neg];
Imeas_all_raw = [Imeas_pos,   Imeas_neg];

[Vmeas_sorted, idx] = sort(Vmeas_all_raw);
Imeas_sorted = Imeas_all_raw(idx);
Vset_sorted  = Vset_all_raw(idx);

% Plot
fig = figure('Color','w');
plot(Vmeas_sorted, Imeas_sorted, 'o-', 'LineWidth', 1.8, 'MarkerSize', 6);
grid on;
xlabel('Voltage(V)', 'FontSize', 14);
ylabel('Current (mA)', 'FontSize', 14);
title('Room temperature IV curve DBR cavity R191108F (Sample connected to pin 1-2)', ...
    'FontSize', 16);
savefig(fig, 'IV_Curve_R191108F_pin1-2.fig');
saveas(fig, 'IV_Curve_R191108F_pin1-2.png');
