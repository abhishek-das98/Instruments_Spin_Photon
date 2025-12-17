% ============================================================
%  LightField time-lapse acquisition (one long run, all frames)
%  - Can capture the spectra for arbitrary long time
%  - Any center wavelength can be set
%  - Plots a 3D surface: X = wavelength, Y = datetime timestamps, Z = counts
%
%  Requirements:
%   - ClassLightFieldWrapper on MATLAB path
%   - ClassLightFieldWrapper has a public method:
%       [spectraAll, wl_nm, tFrames] = acquireTimed_AllFrames(...)
%
%  Ouputs
%  - Postprocesses the data to get rid of the astronomical rays
%  - Generates a 2D surface plot w.r.t. wavelength and timestamps
%  - Saves the post-processed data in an excel sheet with time and date in
%  the folder name
% ============================================================

clc; clear; close all;

% ---------- User settings ----------
center_nm        = 920;    % center wavelength (nm)
exposure_ms      = 2000;   % exposure time (ms)
duration_min     = 30;      % total acquisition time (minutes)
progress_period  = 10;     % print status every N seconds

% ---------- Connect ----------
lf = ClassLightFieldWrapper(true, "Experiment_Spectrometer_Mode");

% ---------- Acquire (one long run, all frames) ----------
[spectraAll, wl_nm, tFrames] = lf.acquireTimed_AllFrames( ...
    center_nm, exposure_ms, duration_min, progress_period);

%lf.close();

% Post-processing, setting the counts that go beyond a particular value to its previous value

Z_fixed = Z;

mask = (Z_fixed > 3000);                 % saturated points
mask(1,:) = false;                       % first row has no "previous" row

Z_fixed(mask) = Z_fixed(circshift(mask, [1 0]));   % copy from previous timestamp

% Difference along time axis
dZ = abs(diff(Z_fixed, 1, 1));    % size: (nFrames-1) x nW

% Identify large jumps
maskJump = (dZ > 500);

% Apply correction: replace current value with previous value
Z_fixed(2:end, :) = Z_fixed(2:end, :) .* (~maskJump) + ...
                     Z_fixed(1:end-1, :) .* maskJump;

% Saving everything to excel sheet

% Create dated filename
todayStr = datestr(datetime('today'), 'yyyy-mm-dd');
fileName = "spectral_data_" + todayStr + ".xlsx";

% Write data
writematrix(X, fileName, 'Sheet', 'Wavelength_nm');
writematrix(Z_fixed, fileName, 'Sheet', 'Intensity');

% Datetime must be written as text
writematrix(string(Y, 'yyyy-MM-dd HH:mm:ss'), ...
            fileName, 'Sheet', 'Timestamps');



% ---------- 3D surface plot (datetime-native) ----------
% Arrange for surf:
%   spectraAll is [nW x nFrames]
%   surf wants Z as [nFrames x nW]
X = wl_nm(:).';          % 1 x nW
Y = tFrames(:);          % nFrames x 1 datetime
Z = spectraAll.';        % nFrames x nW

[XX, YY] = meshgrid(X, Y);

figure;
surf(XX, YY, Z, 'EdgeColor', 'none');
shading interp;

xlabel('Wavelength (nm)');
ylabel('Timestamp');
zlabel('Counts');
title(sprintf('LightField time-lapse (Center %g nm, Exposure %g ms, Duration %g min)', ...
    center_nm, exposure_ms, duration_min));

colorbar;
view(45, 35);
grid on;
