classdef (ConstructOnLoad = true) ClassLightFieldWrapper < handle
    % ClassLightFieldWrapper
    % MATLAB wrapper for Teledyne Princeton Instruments LightField
    % automation (.NET Add-ins/Automation SDK).
    %
    % Key idea: control is via .NET Automation + IExperiment SetValue/GetValue
    % See LightField automation docs installed with LightField.
    %
    % Typical usage:
    %   lf = ClassLightFieldWrapper(true, "Experiment_Spectrometer_Mode");
    %   lf.setExposureMs(50);
    %   lf.setFrames(1);
    %   [data, wl] = lf.acquire();   % data can be 2D/3D or cell array (multi-ROI)
    %   lf.close();

    properties (SetAccess = private)
        automation   % PrincetonInstruments.LightField.Automation.Automation
        application  % automation.LightFieldApplication
        experiment   % application.Experiment
        addinbase    % PrincetonInstruments.LightField.AddIns.AddInBase
    end

    properties (Access = private)
        % Default install locations (adjust if your LightField version differs)
        AutomationDll = "C:\Program Files\Princeton Instruments\LightField\PrincetonInstruments.LightField.AutomationV4.dll";
        AddInViewDll  = "C:\Program Files\Princeton Instruments\LightField\AddInViews\PrincetonInstruments.LightFieldViewV4.dll";
        SupportDll    = "C:\Program Files\Princeton Instruments\LightField\PrincetonInstruments.LightFieldAddInSupportServices.dll";

        ExperimentName (1,1) string = "Experiment_Spectrometer_Mode";
        Visible (1,1) logical = true;
    end

    methods
        function obj = ClassLightFieldWrapper(visible, experimentName, dllPaths)
            % Constructor
            %
            % visible (optional): true/false to show LightField GUI
            % experimentName (optional): LightField experiment to load
            % dllPaths (optional): struct with fields AutomationDll, AddInViewDll, SupportDll

            if nargin >= 1 && ~isempty(visible)
                obj.Visible = logical(visible);
            end
            if nargin >= 2 && ~isempty(experimentName)
                obj.ExperimentName = string(experimentName);
            end
            if nargin >= 3 && ~isempty(dllPaths)
                if isfield(dllPaths, 'AutomationDll'), obj.AutomationDll = string(dllPaths.AutomationDll); end
                if isfield(dllPaths, 'AddInViewDll'),  obj.AddInViewDll  = string(dllPaths.AddInViewDll);  end
                if isfield(dllPaths, 'SupportDll'),    obj.SupportDll    = string(dllPaths.SupportDll);    end
            end

            obj.connect();
            obj.loadExperiment(obj.ExperimentName);
        end

        function delete(obj)
            % Ensure resources are released if user forgets to call close()
            obj.close();
        end

        function connect(obj)
            % Load assemblies and create LightField automation instance
            obj.assertFilesExist();

            % Load assemblies once per MATLAB session
            ClassLightFieldWrapper.loadAssembliesOnce(obj.AddInViewDll, obj.AutomationDll, obj.SupportDll);

            import PrincetonInstruments.LightField.AddIns.*

            obj.addinbase   = PrincetonInstruments.LightField.AddIns.AddInBase();
            obj.automation  = PrincetonInstruments.LightField.Automation.Automation(obj.Visible, []);
            obj.application = obj.automation.LightFieldApplication;
            obj.experiment  = obj.application.Experiment;
        end

        function close(obj)
            % Dispose LightField automation cleanly
            try
                if ~isempty(obj.experiment) && obj.experiment.IsRunning
                    obj.experiment.Stop();
                    pause(0.2);
                end
            catch
            end

            try
                if ~isempty(obj.automation) && ~obj.automation.IsDisposed
                    obj.automation.Dispose();
                end
            catch
            end

            obj.automation  = [];
            obj.application = [];
            obj.experiment  = [];
            obj.addinbase   = [];
        end

        function stopIfRunning(obj)
            % Prevent crashes: stop acquisition before changing settings
            if isempty(obj.experiment); return; end
            if obj.experiment.IsRunning
                obj.experiment.Stop();
                fprintf('Stopped a running acquisition to avoid LightField instability.\n');
                pause(0.5);
            end
        end

        function loadExperiment(obj, experimentName)
            obj.stopIfRunning();
            obj.experiment.Load(string(experimentName));
        end

        function setValue(obj, settingKey, value)
            % Generic SetValue with validation
            if obj.experiment.Exists(settingKey)
                if obj.experiment.IsValid(settingKey, value)
                    obj.stopIfRunning();
                    obj.experiment.SetValue(settingKey, value);
                else
                    error("LightField:InvalidValue", "Value is not valid for the requested setting.");
                end
            else
                error("LightField:UnknownSetting", "Setting key does not exist in the current experiment.");
            end
        end

        function value = getValue(obj, settingKey)
            % Generic GetValue
            if obj.experiment.Exists(settingKey)
                obj.stopIfRunning();
                value = obj.experiment.GetValue(settingKey);
            else
                error("LightField:UnknownSetting", "Setting key does not exist in the current experiment.");
            end
        end

        function setExposureMs(obj, exposureMs)
            import PrincetonInstruments.LightField.AddIns.*
            obj.setValue(CameraSettings.ShutterTimingExposureTime, exposureMs);
        end

        function setFrames(obj, nFrames)
            import PrincetonInstruments.LightField.AddIns.*
            obj.setValue(ExperimentSettings.FrameSettingsFramesToStore, nFrames);
        end

        function setCenterWavelengthNm(obj, lambdaNm)
            import PrincetonInstruments.LightField.AddIns.*
            obj.setValue(SpectrometerSettings.GratingCenterWavelength, lambdaNm);
        end

        function lambdaNm = getCenterWavelengthNm(obj)
            import PrincetonInstruments.LightField.AddIns.*
            lambdaNm = obj.getValue(SpectrometerSettings.GratingCenterWavelength);
        end

        function setExitPort(obj, whichPort)
            % whichPort: "Front" or "Side"
            import PrincetonInstruments.LightField.AddIns.*

            whichPort = lower(string(whichPort));
            switch whichPort
                case "front"
                    obj.setValue(SpectrometerSettings.OpticalPortExitSelected, OpticalPortLocation.FrontExit);
                case "side"
                    obj.setValue(SpectrometerSettings.OpticalPortExitSelected, OpticalPortLocation.SideExit);
                otherwise
                    error("LightField:BadPort", "whichPort must be ""Front"" or ""Side"".");
            end
        end

        function [data, wavelength] = acquire(obj)
            % Acquire once, return:
            % - wavelength: numeric vector in nm if available, else []
            % - data:
            %     * single ROI: 2D (H x W) if 1 frame, else 3D (H x W x F)
            %     * multi ROI : cell array {roi}(H x W) or {roi}(H x W x F)

            import System.IO.FileAccess;

            obj.stopIfRunning();
            obj.experiment.Acquire();

            wavelength = [];
            accessedWl = false;

            while obj.experiment.IsRunning
                if ~accessedWl
                    if isempty(obj.experiment.SystemColumnCalibration)
                        wavelength = [];
                        accessedWl = true;
                    else
                        n = obj.experiment.SystemColumnCalibration.Length;
                        wl = zeros(n, 1);
                        for k = 0:n-1
                            wl(k+1) = obj.experiment.SystemColumnCalibration.Get(k);
                        end
                        wavelength = wl;
                        accessedWl = true;
                    end
                end
                pause(0.05);
            end

            lastfile  = obj.application.FileManager.GetRecentlyAcquiredFileNames.GetItem(0);
            imageset  = obj.application.FileManager.OpenFile(lastfile, FileAccess.Read);

            data = ClassLightFieldWrapper.parseImageSet(imageset);
        end

        function [spectrum, wl] = acquireSpectrum1D(obj, mode)
            % Helper: turn the acquired frame into a 1D spectrum.
            % mode:
            %   "sumY"  : sum over rows (common for spectrometer line images)
            %   "meanY" : mean over rows
            % If the acquisition is already 1D in your setup, this may be a no-op.

            if nargin < 2, mode = "sumY"; end
            mode = lower(string(mode));

            [img, wl] = obj.acquire();

            if iscell(img)
                error("LightField:MultiROI", "acquireSpectrum1D expects a single ROI. Your experiment has multiple ROIs.");
            end
            if ndims(img) == 3
                img = img(:,:,1); % take first frame by default
            end

            switch mode
                case "sumy"
                    spectrum = sum(img, 1).';   % W x 1
                case "meany"
                    spectrum = mean(img, 1).';
                otherwise
                    error("LightField:BadMode", "mode must be ""sumY"" or ""meanY"".");
            end
        end
    end

    methods (Access = private)
        function assertFilesExist(obj)
            if ~isfile(obj.AutomationDll)
                error("LightField:MissingDLL", "Automation DLL not found: %s", obj.AutomationDll);
            end
            if ~isfile(obj.AddInViewDll)
                error("LightField:MissingDLL", "AddInView DLL not found: %s", obj.AddInViewDll);
            end
            if ~isfile(obj.SupportDll)
                error("LightField:MissingDLL", "Support DLL not found: %s", obj.SupportDll);
            end
        end
    end

    methods (Static, Access = private)
        function loadAssembliesOnce(addinDll, automationDll, supportDll)
            persistent alreadyLoaded
            if isempty(alreadyLoaded) || ~alreadyLoaded
                NET.addAssembly(char(addinDll));
                NET.addAssembly(char(automationDll));
                NET.addAssembly(char(supportDll));
                alreadyLoaded = true;
            end
        end

        function data = parseImageSet(imageset)
            % Normalize ImageDataSet to MATLAB arrays (matches your original logic)
            if imageset.Regions.Length == 1
                if imageset.Frames == 1
                    frame = imageset.GetFrame(0,0);
                    data  = reshape(frame.GetData().double, frame.Width, frame.Height).';
                else
                    data = [];
                    for i = 0:imageset.Frames-1
                        frame = imageset.GetFrame(0,i);
                        buf   = reshape(frame.GetData().double, frame.Width, frame.Height).';
                        data  = cat(3, data, buf);
                    end
                end
            else
                data = cell(imageset.Regions.Length, 1);
                for r = 0:imageset.Regions.Length-1
                    if imageset.Frames == 1
                        frame = imageset.GetFrame(r,0);
                        buf   = reshape(frame.GetData().double, frame.Width, frame.Height).';
                    else
                        buf = [];
                        for i = 0:imageset.Frames-1
                            frame = imageset.GetFrame(r,i);
                            tmp   = reshape(frame.GetData().double, frame.Width, frame.Height).';
                            buf   = cat(3, buf, tmp);
                        end
                    end
                    data{r+1} = buf;
                end
            end
        end
    end
end
