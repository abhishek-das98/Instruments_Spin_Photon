% In the lab, the spectrometer and the magnetic field are connected to two
% different computers
% Using these code, we can combine two different data (From two different
% excel sheets created from codes 'MagnetRamp_TimePlot.m' and
% 'CapturePlotSaveSpectrum.m') utilizing the timestamps, and create a 3D
% surface plot combining the magnetic field and the original spectra

% Creates 4 different plots (Using different combinations of Zoomed in/out
% and normalized/unnormalized

clc; clear; close all;

magFile  = "MagnetRamp_20251217_100653.xlsx";    % <--- Provide the magnetic field file
specFile = "spectral_data.xlsx";                 % <--- Provide the spectra file 

%% ---- Magnet data ----

magT = readtable(magFile, "Sheet","Sheet1", "TextType","string");

ts = magT.Timestamp;

if isdatetime(ts)
    % Already imported correctly
    magTime = ts;

elseif isnumeric(ts)
    % Excel serial numbers
    magTime = datetime(ts, "ConvertFrom","excel");

else
    % Text: trim and parse, allowing optional seconds
    s = strtrim(string(ts));

    magTime = NaT(size(s));
    for i = 1:numel(s)
        if s(i)=="" || ismissing(s(i)), continue; end

        try
            magTime(i) = datetime(s(i), "InputFormat","MM/dd/yyyy HH:mm");
        catch
            try
                magTime(i) = datetime(s(i), "InputFormat","MM/dd/yyyy HH:mm:ss");
            catch
                % last resort: let MATLAB try to infer
                magTime(i) = datetime(s(i));
            end
        end
    end

    if any(isnat(magTime))
        bad = find(isnat(magTime), min(10,nnz(isnat(magTime))), "first");
        disp("Bad magnet timestamp examples:");
        disp(s(bad));
        error("Some magnet timestamps still couldn't be parsed (examples shown).");
    end
end

B_T = magT.MagneticField_T;

% Sort (important for interp1)
% Ensure sorted
[magTime, idx] = sort(magTime);
B_T = B_T(idx);

% Remove duplicate timestamps (interp1 needs strictly increasing X)
[tMagNum, iu] = unique(datenum(magTime), 'stable');
B_Tu = B_T(iu);


%% ---- Spectral data ----
wl_nm = readmatrix(specFile, "Sheet","Wavelength_nm");
wl_nm = wl_nm(:).';

I = readmatrix(specFile, "Sheet","Intensity");

% Robust timestamps read (Sheet 3)
tCell = readcell(specFile, "Sheet","Timestamps");
tCell = tCell(:);
s = strtrim(string(tCell));
s = s(s ~= "" & ~ismissing(s));
if contains(lower(s(1)), "time"); s(1) = []; end

specTime = datetime(s, "InputFormat","yyyy-MM-dd HH:mm:ss");

% Match intensity rows to timestamps length (in case an extra row slipped in)
Nt = min(size(I,1), numel(specTime));
I = I(1:Nt,:);
specTime = specTime(1:Nt);

%% ---- Keep only spectra during magnet recording window ----
tol = minutes(1);  % important since magnet time has minute resolution
keep = specTime >= (min(magTime) - tol) & specTime <= (max(magTime) + tol);

specTime_k = specTime(keep);
I_k        = I(keep,:);

if isempty(specTime_k)
    error("No overlap between magnet and spectral timestamps. Increase tol or check time bases.");
end

%% ---- Map time -> B ----
tSpecNum = datenum(specTime_k);

% Interpolate (no extrapolation by default → NaNs appear outside range)
B_spec = interp1(tMagNum, B_Tu, tSpecNum, "linear");
% If you prefer nearest:
% B_spec = interp1(tMagNum, B_Tu, tSpecNum, "nearest");

ok = ~isnan(B_spec) & isfinite(B_spec);

B_spec = B_spec(ok);
I_k    = I_k(ok,:);

% Sort by B so y-axis is monotonic
[B_spec, idxB] = sort(B_spec);
I_k = I_k(idxB,:);

%% ===================== 4 FIGURES =====================

% ---- Normalization per timestamp (per row) ----
rowMax = max(I_k, [], 2);
rowMax(rowMax==0) = 1;                 % avoid divide-by-zero
I_norm = I_k ./ rowMax;                % each timestamp normalized to 1

% ---- Choose wavelength window ----
wl_min = 916;      % <-- change these
wl_max = 920;      % <-- change these
maskWL = (wl_nm >= wl_min) & (wl_nm <= wl_max);

wl_win   = wl_nm(maskWL);
I_win    = I_k(:, maskWL);
I_norm_w = I_norm(:, maskWL);

% Meshgrids
[WL_full, BB_full] = meshgrid(wl_nm,  B_spec);
[WL_win,  BB_win ] = meshgrid(wl_win, B_spec);

% -------- Figure 1: Unnormalized, full range --------
figure('Color','w');
surf(WL_full, BB_full, I_k, 'EdgeColor','none');
xlabel('Wavelength (nm)'); ylabel('Magnetic Field (T)'); zlabel('Intensity (counts)');
title('Unnormalized: Full wavelength range');
colormap turbo; colorbar; view(45,30); camlight headlight; lighting gouraud;

% -------- Figure 2: Normalized, full range --------
figure('Color','w');
surf(WL_full, BB_full, I_norm, 'EdgeColor','none');
xlabel('Wavelength (nm)'); ylabel('Magnetic Field (T)'); zlabel('Normalized intensity');
title('Normalized per timestamp: Full wavelength range');
colormap turbo; colorbar; view(45,30); camlight headlight; lighting gouraud;

% -------- Figure 3: Unnormalized, wavelength window --------
figure('Color','w');
surf(WL_win, BB_win, I_win, 'EdgeColor','none');
xlabel('Wavelength (nm)'); ylabel('Magnetic Field (T)'); zlabel('Intensity (counts)');
title(sprintf('Unnormalized: Wavelength window %.1f–%.1f nm', wl_min, wl_max));
colormap turbo; colorbar; view(45,30); camlight headlight; lighting gouraud;

% -------- Figure 4: Normalized, wavelength window --------
figure('Color','w');
surf(WL_win, BB_win, I_norm_w, 'EdgeColor','none');
xlabel('Wavelength (nm)'); ylabel('Magnetic Field (T)'); zlabel('Normalized intensity');
title(sprintf('Normalized per timestamp: Wavelength window %.1f–%.1f nm', wl_min, wl_max));
colormap turbo; colorbar; view(45,30); camlight headlight; lighting gouraud;
