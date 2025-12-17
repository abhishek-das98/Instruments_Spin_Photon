function plotSpectraFromCSV(fileList, plotType, varargin)
% plotSpectraFromCSV  Plot spectra from CSV files as overlayed curves or subplots.
% A handy MATLAB code to plot the spectra, in a style that you prefer
% Choose between overlayed plot/subfigure style plot
% Input the titles/subtitles
%
% Acquire the experimental data from the Lightfield Software, then export
% as a CSV file
% After that, use this code to plot
%   plotSpectraFromCSV(fileList, plotType, ...)
%
%   INPUTS
%   ------
%   fileList   : Cell array of file names or string array.
%                Each CSV must have:
%                   Column 1 = wavelength (nm)
%                   Column 2 = intensity (counts)
%
%   plotType   : 'overlayed' or 'subplots'
%
%   EXTRA ARGS
%   ----------
%   If plotType = 'overlayed'
%       varargin{1} = overallTitle   (char/string)       [optional]
%       varargin{2} = legendLabels   (cell array/strings)[optional]
%
%   If plotType = 'subplots'
%       varargin{1} = overallTitle   (char/string)       [optional]
%       varargin{2} = subplotTitles  (cell array/strings)[optional]
%
%   Examples:
%       files = {'12-10_cavity_2_180mA_0V_exp1s.csv', ...
%                '12_kG_Magnetic.csv', ...
%                '180mA_50kG.csv'};
%
%       % Overlayed plot with legend labels
%       plotSpectraFromCSV(files, 'overlayed', ...
%           'Spectrum at Different Applied Magnetic Fields', ...
%           {'0 T', '1.2 T', '5.0 T'});
%
%       % Subplots with individual titles and overall title
%       plotSpectraFromCSV(files, 'subplots', ...
%           'Spectrum at Different Applied Magnetic Fields', ...
%           {'0 T', '1.2 T', '5.0 T'});

% ---------- Normalize fileList input ----------
if ischar(fileList) || (isstring(fileList) && isscalar(fileList))
    fileList = {char(fileList)};
elseif isstring(fileList)
    fileList = cellstr(fileList);
end

nFiles = numel(fileList);
if nFiles == 0
    error('fileList must contain at least one file name.');
end

% ---------- Read all spectra ----------
lambda = cell(nFiles, 1);
intensity = cell(nFiles, 1);

for k = 1:nFiles
    data = readmatrix(fileList{k});
    if size(data, 2) < 2
        error('File "%s" does not have at least two columns.', fileList{k});
    end
    lambda{k}    = data(:, 1);
    intensity{k} = data(:, 2);
end

% ---------- Handle optional arguments ----------
plotType = lower(string(plotType));

switch plotType
    case "overlayed"
        % ---------- Parse inputs ----------
        if numel(varargin) < 2
            error(['For ''overlayed'' plots, you must provide:\n' ...
                '1) overallTitle\n' ...
                '2) legendLabels (same order as fileList)']);
        end

        overallTitle = varargin{1};
        legendLabels = varargin{2};

        % ---------- Validate legend labels ----------
        if numel(legendLabels) ~= nFiles
            error('Number of legend labels (%d) must match number of files (%d).', ...
                numel(legendLabels), nFiles);
        end

        % ---------- Make overlayed plot ----------
        figure;
        hold on; grid on;

        h = gobjects(nFiles, 1);

        % Plot in EXACT same order as fileList
        for k = 1:nFiles
            h(k) = plot(lambda{k}, intensity{k}, 'LineWidth', 1.6);
        end

        xlabel('Wavelength (nm)', 'FontSize', 12);
        ylabel('Intensity (counts)', 'FontSize', 12);

        % Legend strictly follows input order
        legend(h, legendLabels, 'Location', 'best', 'FontSize', 11);

        title(overallTitle, 'FontSize', 14);

        hold off;


    case "subplots"
        overallTitle  = '';
        subplotTitles = [];

        if numel(varargin) >= 1
            overallTitle = varargin{1};
        end
        if numel(varargin) >= 2
            subplotTitles = varargin{2};
        end

        % Auto-generate subplot titles from file names if not provided
        if isempty(subplotTitles)
            subplotTitles = cell(nFiles, 1);
            for k = 1:nFiles
                [~, name, ~] = fileparts(fileList{k});
                subplotTitles{k} = name;
            end
        end

        if numel(subplotTitles) ~= nFiles
            error('Number of subplotTitles (%d) must match number of files (%d).', ...
                numel(subplotTitles), nFiles);
        end

        % ---------- Make subplots ----------
        figure;
        for k = 1:nFiles
            subplot(nFiles, 1, k);
            plot(lambda{k}, intensity{k}, 'LineWidth', 1.6);
            grid on;
            xlabel('Wavelength (nm)', 'FontSize', 11);
            ylabel('Intensity (counts)', 'FontSize', 11);
            title(subplotTitles{k}, 'FontSize', 13);
        end

        if ~isempty(overallTitle)
            sgtitle(overallTitle, 'FontSize', 14);
        end

    otherwise
        error('plotType must be either "overlayed" or "subplots".');
end
end
