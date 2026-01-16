function results = AnalyzeCavityFromCSV( ...
    csvFile, ...
    MinWavelengthForPlot, MaxWavelengthForPlot, ...
    MaxCountsForPlot, SpectrometerExposure_s, ...
    CavityName, ExcitationPower, GratingMode, SampleName, ...
    FigName, InitParams ...
)
% AnalyzeCavityFromCSV
% Reads spectrum from CSV, fits Lorentzian, extracts lambda0, bandwidth, Q,
% plots and saves PNG + FIG.
%
% CSV format:
%   Column 1 → wavelength (nm)
%   Column 2 → intensity (counts)

    % -------------------- Read CSV --------------------
    T = readtable(csvFile);

    % Take first two columns as wavelength and intensity
    wl = T{:,1};
    I  = T{:,2};

    wl = wl(:);
    I  = I(:);

    % Remove NaNs / invalid rows
    good = isfinite(wl) & isfinite(I);
    wl = wl(good);
    I  = I(good);

    % Sort by wavelength
    [wl, idx] = sort(wl);
    I = I(idx);

    % -------------------- Crop for fit/plot --------------------
    inWin = (wl >= MinWavelengthForPlot) & (wl <= MaxWavelengthForPlot);
    wl_fit = wl(inWin);
    I_fit  = I(inWin);

    if numel(wl_fit) < 10
        error("Not enough data points inside the wavelength window to fit.");
    end

    % -------------------- Lorentzian model --------------------
    % p = [lambda0_nm, FWHM_nm, amplitude, offset]
    lorentz = @(p,x) p(4) + p(3) ./ (1 + (2*(x - p(1))./p(2)).^2);

    % Auto initial guess if not provided
    if nargin < 11 || isempty(InitParams)
        [Ipk, kpk] = max(I_fit);
        lambda0_0 = wl_fit(kpk);
        y0_0 = median(I_fit);
        A_0  = max(Ipk - y0_0, eps);

        halfLevel = y0_0 + 0.5*(Ipk - y0_0);
        leftIdx  = find(I_fit(1:kpk) <= halfLevel, 1, 'last');
        rightIdx = kpk - 1 + find(I_fit(kpk:end) <= halfLevel, 1, 'first');

        if isempty(leftIdx) || isempty(rightIdx)
            fwhm_0 = (MaxWavelengthForPlot - MinWavelengthForPlot)/20;
        else
            fwhm_0 = wl_fit(rightIdx) - wl_fit(leftIdx);
            if ~isfinite(fwhm_0) || fwhm_0 <= 0
                fwhm_0 = (MaxWavelengthForPlot - MinWavelengthForPlot)/20;
            end
        end

        InitParams = [lambda0_0, fwhm_0, A_0, y0_0];
    end

    % Objective function
    objfun = @(p) sum((I_fit - lorentz(p, wl_fit)).^2);

    opts = optimset('Display','off');
    [pBest, fval, exitflag] = fminsearch(objfun, InitParams, opts);

    yfitted = lorentz(pBest, wl_fit);

    Lambda_nm = pBest(1);
    FWHM_nm   = abs(pBest(2));
    Q         = Lambda_nm / FWHM_nm;

    % -------------------- Plot --------------------
    fig = figure('Color','w');
    hold on;
    plot(wl, I, '.', 'MarkerSize', 18);
    plot(wl_fit, yfitted, '-', 'LineWidth', 3);

    excStr = stringifyValue(ExcitationPower);

    title(sprintf('Spectrum | Sample: %s | Cavity: %s | P_exc: %s', ...
        SampleName, CavityName, excStr), 'Interpreter','none');

    xlabel('Wavelength [nm]');
    ylabel(sprintf('Fluorescence [counts / %.4g s]', SpectrometerExposure_s));

    legend('measurement', ...
        sprintf('fit: \\lambda_0=%.4f nm, FWHM=%.4g nm, Q=%.4g | grating=%s', ...
        Lambda_nm, FWHM_nm, Q, stringifyValue(GratingMode)), ...
        'FontSize', 9, 'Location','best');

    xlim([MinWavelengthForPlot MaxWavelengthForPlot]);
    ylim([0 MaxCountsForPlot]);
    set(gca,'FontSize',18);
    grid on; box on;

    % -------------------- Save --------------------
    FigName = char(FigName);
    saveas(fig, [FigName '.png']);
    saveas(fig, [FigName '.fig']);


    % -------------------- Output --------------------
    results = struct( ...
        'lambda0_nm', Lambda_nm, ...
        'fwhm_nm',    FWHM_nm, ...
        'Q',          Q, ...
        'params',     pBest, ...
        'fval',       fval, ...
        'exitflag',   exitflag ...
    );
end

function s = stringifyValue(v)
    if isnumeric(v)
        s = num2str(v);
    elseif isstring(v) || ischar(v)
        s = char(v);
    else
        s = "<unprintable>";
    end
end
