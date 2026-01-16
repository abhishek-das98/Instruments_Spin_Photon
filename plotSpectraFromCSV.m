function plotSpectraFromCSV(fileList, plotType, varargin)
% plotSpectraFromCSV
% -------------------------------------------------------------
% This function plots optical spectra stored in CSV files.
%
% You can:
%    Plot all spectra on the same figure (overlayed)
%    Plot each spectrum in its own subplot (stacked)
%
% Each CSV file must contain:
%   Column 1 → Wavelength (nm)
%   Column 2 → Intensity (counts)
%
% -------------------------------------------------------------
% BASIC IDEA
% -------------------------------------------------------------
% 1) Read wavelength & intensity from CSV files
% 2) Decide how to plot (overlayed or subplots)
% 3) Add labels, titles, legends
% 4) Optionally save the figure (.fig + .png)
% -------------------------------------------------------------


%% -------------------------------------------------------------
% 1) Make sure fileList is always a cell array
% -------------------------------------------------------------
% MATLAB loops over cell arrays cleanly.
% If the user provides a single file name, convert it to a cell.

if ischar(fileList) || (isstring(fileList) && isscalar(fileList))
    fileList = {char(fileList)};
elseif isstring(fileList)
    fileList = cellstr(fileList);
end

nFiles = numel(fileList);   % number of spectrum files

if nFiles == 0
    error('fileList must contain at least one file name.');
end


%% -------------------------------------------------------------
% 2) Read data from CSV files
% -------------------------------------------------------------
% Store wavelength and intensity for each file separately.

lambda    = cell(nFiles, 1);
intensity = cell(nFiles, 1);

for k = 1:nFiles
    data = readmatrix(fileList{k});   % read CSV file

    % Basic safety check
    if size(data, 2) < 2
        error('File "%s" must have at least two columns.', fileList{k});
    end

    lambda{k}    = data(:,1);
    intensity{k} = data(:,2);
end


%% -------------------------------------------------------------
% 3) Decide how to plot
% -------------------------------------------------------------
% plotType must be either:
%   "overlayed" → all spectra on one axes
%   "subplots"  → one spectrum per subplot

plotType = lower(string(plotType));

switch plotType

    % =========================================================
    % OVERLAYED PLOT
    % =========================================================
    case "overlayed"

        % Overall title is required
        if numel(varargin) < 1
            error("For 'overlayed', overallTitle is required.");
        end
        overallTitle = varargin{1};

        % Legend labels (optional for 1 file)
        legendLabels = [];
        if numel(varargin) >= 2 && ~isempty(varargin{2})
            legendLabels = varargin{2};
        end

        if nFiles > 1
            if isempty(legendLabels)
                error('legendLabels required when plotting multiple spectra.');
            end
            if numel(legendLabels) ~= nFiles
                error('Number of legend labels must match number of files.');
            end
        end

        % Exposure time (used only for axis label)
        exposureTime_s = [];
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            exposureTime_s = varargin{3};
            validateExposureTime(exposureTime_s);
        end

        % Optional file name for saving
        saveFigName = [];
        if numel(varargin) >= 4 && ~isempty(varargin{4})
            saveFigName = varargin{4};
        end

        % -------- Create the figure --------
        fig = figure('Color','w');
        hold on; grid on;

        h = gobjects(nFiles,1);
        for k = 1:nFiles
            h(k) = plot(lambda{k}, intensity{k}, 'LineWidth', 1.6);
        end

        xlabel('Wavelength (nm)', 'FontSize', 12);

        if isempty(exposureTime_s)
            ylabel('Intensity (counts)', 'FontSize', 12);
        else
            ylabel(sprintf('Intensity (counts / %.3gs)', exposureTime_s), ...
                   'FontSize', 12);
        end

        title(overallTitle, 'FontSize', 14);

        if ~isempty(legendLabels)
            legend(h, legendLabels, 'Location', 'best', 'FontSize', 11);
        end

        hold off;

        % -------- Save figure if requested --------
        if ~isempty(saveFigName)
            savefig(fig, saveFigName + ".fig");                      % Editable MATLAB figure
            exportgraphics(fig, saveFigName + ".png", ...
                           "Resolution", 300);                      % High-res image
        end


    % =========================================================
    % SUBPLOTS
    % =========================================================
    case "subplots"

        % Optional inputs
        overallTitle  = '';
        subplotTitles = [];

        if numel(varargin) >= 1
            overallTitle = varargin{1};
        end
        if numel(varargin) >= 2
            subplotTitles = varargin{2};
        end

        exposureTime_s = [];
        if numel(varargin) >= 3 && ~isempty(varargin{3})
            exposureTime_s = varargin{3};
            validateExposureTime(exposureTime_s);
        end

        saveFigName = [];
        if numel(varargin) >= 4 && ~isempty(varargin{4})
            saveFigName = varargin{4};
        end

        % If no subplot titles are given, use file names
        if isempty(subplotTitles)
            subplotTitles = cell(nFiles,1);
            for k = 1:nFiles
                [~, name, ~] = fileparts(fileList{k});
                subplotTitles{k} = name;
            end
        end

        fig = figure('Color','w');

        % Plot one spectrum per subplot
        for k = 1:nFiles
            subplot(nFiles,1,k);
            plot(lambda{k}, intensity{k}, 'LineWidth', 1.6);
            grid on;

            xlabel('Wavelength (nm)', 'FontSize', 11);

            if isempty(exposureTime_s)
                ylabel('Intensity (counts)', 'FontSize', 11);
            else
                ylabel(sprintf('counts / %.3gs', exposureTime_s), ...
                       'FontSize', 11);
            end

            title(subplotTitles{k}, 'FontSize', 13);
        end

        if ~isempty(overallTitle)
            sgtitle(overallTitle, 'FontSize', 14);
        end

        % -------- Save figure if requested --------
        if ~isempty(saveFigName)
            savefig(fig, saveFigName + ".fig");
            exportgraphics(fig, saveFigName + ".png", ...
                           "Resolution", 300);
        end

    otherwise
        error('plotType must be "overlayed" or "subplots".');
end

end


%% -------------------------------------------------------------
% Helper function: exposure time validation
% -------------------------------------------------------------
% Ensures exposure time is physically meaningful.

function validateExposureTime(t)
if ~isscalar(t) || ~isnumeric(t) || isnan(t) || isinf(t) || t <= 0
    error('exposureTime_s must be a positive scalar (seconds).');
end
end
