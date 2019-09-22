function hgrc
%HGRC Master startup MATLAB file for Handle Graphics.
%   HGRC is automatically executed by MATLAB during startup.
%   It establishes the default figure size and sets a few uicontrol defaults.
%
%	On multi-user or networked systems, the system manager can put
%	any messages, definitions, etc. that apply to all users here.
%
%   HGRC also invokes a STARTUPHG command if the file 'startupHG.m'
%   exists on the MATLAB path.

%   Copyright 1984-2015 The MathWorks, Inc.
try    
% Set the default figure position, in pixels.
% On small screens, make figure smaller, with same aspect ratio.
% Determine the width and height of the primary screen
    screen = get(groot, 'ScreenSize');
width = screen(3) - screen(1);
height = screen(4) - screen(2);
if any(screen(3:4) ~= 1)  % don't change default if screensize == [1 1]
  if ~ismac % For PC and Linux
    margin = 100;
    if height >= 500
      mwwidth = 560; mwheight = 420;
      scaling = max(1, get(groot,'screenpixelsperinch')/96);           
      mwwidth = mwwidth * scaling;
      mwheight = mwheight * scaling; 
      margin = margin * scaling;
    else
      mwwidth = 560; mwheight = 375;
    end
    left = screen(1) + (width - mwwidth)/2;
    bottom = height - mwheight - margin - screen(2);
  else % For Mac
    if height > 768
      mwwidth = 560; mwheight = 420;
      left = screen(1) + (width-mwwidth)/2;
      bottom = height-mwheight -100 - screen(2);
    else  % for screens that aren't so high
      mwwidth = 512; mwheight = 384;
      left = screen(1) + (width-mwwidth)/2;
      bottom = height-mwheight -76 - screen(2);
    end
  end
  % round off to the closest integer.
  left = floor(left); bottom = floor(bottom);
  mwwidth = floor(mwwidth); mwheight = floor(mwheight);

  rect = [ left bottom mwwidth mwheight ];
        set(groot, 'DefaultFigurePosition',rect);
end

%% Set the default PaperPositionMode 
pposModePref = 'auto';
% look for preference setting
%   set via matlab.graphics.internal.setPrintPreferences('DefaultPaperPositionMode', mode);
%      where   mode   is a string containing either 'auto' or 'manual'
if ispref('FigurePrinting', 'DefaultPaperPositionMode')
   prefs = getpref('FigurePrinting');
   if isfield(prefs, 'DefaultPaperPositionMode') 
       theMode = prefs.DefaultPaperPositionMode; 
   else 
       theMode = [];
   end
   if ischar(theMode) && any(strcmp(theMode, {'auto', 'manual'}))
       pposModePref = theMode;
   end
end
set(groot,'DefaultFigurePaperPositionMode', pposModePref);

% MATLAB versions prior to R2015b used 'manual' as the default
% set(groot,'DefaultFigurePaperPositionMode', 'manual');

    
%% Uncomment the next group of lines to make uicontrols, uimenus
%% and lines look better on monochrome displays.
    %if get(groot,'ScreenDepth')==1,
    %   set(groot,'DefaultUIControlBackgroundColor','white');
    %   set(groot,'DefaultAxesLineStyleOrder','-|--|:|-.');
    %   set(groot,'DefaultAxesColorOrder',[0 0 0]);
    %   set(groot,'DefaultFigureColor',[1 1 1]);
%end

%% Uncomment the next line to use Letter paper and inches
%defaultpaper = 'usletter'; defaultunits = 'inches'; defaultsize = [8.5 11.0];

%% A4 paper size is 21.0 x 29.7
a4Size = [21.0 29.7];

%% Uncomment the next line to use A4 paper and centimeters
%defaultpaper = 'A4'; defaultunits = 'centimeters'; defaultsize = a4Size;

%% If neither of the above lines are uncommented then guess
%% which papertype and paperunits to use based on ISO 3166 country code.
if usejava('jvm') && ~exist('defaultpaper','var')
  if any(strncmpi(char(java.util.Locale.getDefault.getCountry), ...
		  {'gb', 'uk', 'fr', 'de', 'es', 'ch', 'nl', 'it', 'ru',...
		   'jp', 'kr', 'tw', 'cn', 'cz', 'sk', 'au', 'dk', 'fi',...
           'gr', 'hu', 'ie', 'il', 'in', 'no', 'pl', 'pt',...
           'ru', 'se', 'tr', 'za','nz','be'},2))
    defaultpaper = 'A4';
    defaultunits = 'centimeters';
    defaultsize = a4Size;
  end
end

%% Set the default if requested
if exist('defaultpaper','var') && exist('defaultunits','var') && ...
        exist('defaultsize', 'var')
  % Handle Graphics defaults
        set(groot,'DefaultFigurePaperType', defaultpaper);
        set(groot,'DefaultFigurePaperUnits',defaultunits);
        set(groot,'DefaultFigurePaperSize', defaultsize);
end

%% CONTROL OVER FIGURE TOOLBARS:
%% The new figure toolbars are visible when appropriate,
%% by default, but that behavior is controllable
%% by users.  By default, they're visible in figures
%% whose MenuBar property is 'figure', when there are
%% no uicontrols present in the figure.  This behavior
%% is selected by the figure ToolBar property being
%% set to its default value of 'auto'.

%% to have toolbars always on, uncomment this:
    %set(groot,'DefaultFigureToolbar','figure')

%% to have toolbars always off, uncomment this:
    %set(groot,'DefaultFigureToolbar','none')

% Temporarily turn off old uitable deprecated function warning.
warning off MATLAB:uitable:DeprecatedFunction

% Temporarily turn off old uiflowcontainer deprecated function warning.
warning off MATLAB:uiflowcontainer:DeprecatedFunction

% Temporarily turn off old uigridcontainer deprecated function warning.
warning off MATLAB:uigridcontainer:DeprecatedFunction

% Temporarily turn off old uitab and uitabgroup deprecated function warning.
warning off MATLAB:uitab:DeprecatedFunction
warning off MATLAB:uitabgroup:DeprecatedFunction

% Temporarily turn off old uitree and uitreenode deprecated function warning.
% NOTE - matlab/toolbox/matlab/timeseries/tTstool.m, test point
% lvlTwo_handleTests, is currently checking for this warning and ignoring
% it.  When we introduce the new documented uitree to replace the old
% undocumented uitree, tTstool.m must be modified to look for this warning
% id.
warning off MATLAB:uitree:DeprecatedFunction
warning off MATLAB:uitreenode:DeprecatedFunction

% Execute startup MATLAB file, if it exists.
startup_exists = exist('startuphg','file');
if startup_exists == 2 || startup_exists == 6
    clear startup_exists
    startuphg
else
    clear startup_exists
end

catch exc
    warning(message('MATLAB:matlabrc:InitHandleGraphics', exc.identifier, exc.message));
end



