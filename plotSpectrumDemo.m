% ============================================================
%  LightField time-lapse acquisition (one long run, all frames)
%  - Uses the "GUI trick": start acquisition first, then set center wavelength
%  - Keeps ALL frames (~1 frame per exposure time)
%  - Plots a 3D surface: X = wavelength, Y = datetime timestamps, Z = counts
%
%  Requirements:
%   - ClassLightFieldWrapper on MATLAB path
%   - ClassLightFieldWrapper has a public method:
%       [spectraAll, wl_nm, tFrames] = acquireTimed_AllFrames(...)
% ============================================================

clc; clear; close all;

% ---------- User settings (edit these) ----------
center_nm        = 920;    % center wavelength (nm)
exposure_ms      = 2000;   % exposure time (ms)
duration_min     = 2;      % total acquisition time (minutes)
progress_period  = 10;     % print status every N seconds

% ---------- Connect ----------
lf = ClassLightFieldWrapper(true, "Experiment_Spectrometer_Mode");

% ---------- Acquire (one long run, all frames) ----------
[spectraAll, wl_nm, tFrames] = lf.acquireTimed_AllFrames( ...
    center_nm, exposure_ms, duration_min, progress_period);

%lf.close();

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
