function createGUIElements(obj)

% -------------------------------------------------------------------------
% Get defaults and load preferences from file
[iPosition, l3DMode] = fGetDefaults(obj);

% -------------------------------------------------------------------------
% Create the main figure
obj.hF = figure(...
    'Visible'               , 'off', ...
    'BusyAction'            , 'cancel', ...
    'Interruptible'         , 'off', ...
    'Units'                 , 'pixels', ...
    'Renderer'              , 'opengl', ...
    'Color'                 , 'k', ...
    'Colormap'              , gray(256), ...
    'MenuBar'               , 'none', ...
    'NumberTitle'           , 'off', ...
    'Name'                  , ['IMAGINE ', obj.sVERSION], ...
    'ResizeFcn'             , @obj.resize, ...
    'CloseRequestFcn'       , @obj.close, ...
    'WindowKeyPressFcn'     , @obj.keyPress, ...
    'WindowKeyReleaseFcn'   , @obj.keyRelease, ...
    'WindowButtonMotionFcn' , @obj.mouseMove, ...
    'WindowScrollWheelFcn'  , @obj.changeImg);

if ~isempty(iPosition)
    set(obj.hF, 'Position', iPosition);
else
    set(obj.hF, 'WindowStyle', 'docked');
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Putting all this in a try statement to prevent a pile-up of invisible
% figures in case anything goes wrong
try
    
    % ---------------------------------------------------------------------
    % Timer objects to realize delayed actions (like hiding of tooltip)
    obj.STimers.hToolTip   = timer('StartDelay', 0.8, 'TimerFcn', @obj.tooltip);
    obj.STimers.hGrid      = timer('StartDelay', 0.5, 'TimerFcn', @obj.restoreGrid);
    obj.STimers.hDrawFancy = timer('StartDelay', 0.1, 'TimerFcn', @obj.draw);
    obj.STimers.hDraw      = timer('ExecutionMode', 'fixedRate', 'Period', 1, 'TimerFcn', @obj.updateData, 'BusyMode', 'drop');
    obj.STimers.hIcons     = timer('StartDelay', 0.1, 'TimerFcn', @obj.resize);
    % ---------------------------------------------------------------------
    
    
    % ---------------------------------------------------------------------
    % Create the bars that contain icons (menu, toolbar and sidebar,
    % context menu)
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Menubar
    obj.SAxes.hMenu  = axes(...
        'Units'             , 'pixels', ...
        'YDir'              , 'reverse', ...
        'Hittest'           , 'off', ...
        'XColor'            , [0.3 0.3 0.3], ...
        'XTick'             , [], ...
        'Visible'           , 'on');
    hold on
    
    obj.SImgs.hMenu = image(...
        'CData'             , repmat(permute(obj.dBGCOLOR'*(0.95 + 0.05.*rand(1, 64)), [2 3 1]), [1 2 1]), ...
        'XData'             , [1, 1000], ...
        'YData'             , [1, 64]);
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Toolbar
    obj.SAxes.hTools = axes(...
        'Units'             , 'pixels', ...
        'YDir'              , 'reverse', ...
        'Hittest'           , 'off', ...
        'XColor'            , obj.dBGCOLOR, ...
        'YColor'            , [0.3 0.3 0.3], ...
        'YTick'             , [], ...
        'Box'               , 'on', ...
        'Visible'           , 'on');
    hold on
    
    obj.SImgs.hTools = image(...
        'CData'             , repmat(permute(obj.dBGCOLOR'*(0.95 + 0.05.*rand(1, 2000)), [2 3 1]), [1 2 1]), ...
        'XData'             , [1, 64], ...
        'YData'             , [1, 2000]);
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Sidebar (sits on a panel)
    obj.SSidebar.hPanel = uipanel(...
        'Parent'                    , obj.hF, ...
        'BackgroundColor'           , obj.dBGCOLOR, ...
        'BorderType'                , 'none', ...
        'Units'                     , 'pixels', ...
        'Visible'                   , 'on', ...
        'Hittest'                   , 'off');
    
    obj.SSidebar.hIcons = axes(...
        'Parent'            , obj.SSidebar.hPanel, ...
        'Units'             , 'pixels', ...
        'Visible'           , 'off', ...
        'YDir'              , 'reverse', ...
        'XTick'             , [], ...
        'YTick'             , [], ...
        'Hittest'           , 'off');
    hold on
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Context menu (needs a black background image for contrast)
    obj.SAxes.hContext = axes(...
        'Parent'            , obj.hF, ...
        'Units'             , 'pixels', ...
        'Position'          , [1 1 1 1], ...
        'YLim'              , [0.5 1.5], ...
        'YDir'              , 'reverse', ...
        'XTick'             , [], ...
        'YTick'             , [], ...
        'Visible'           , 'off', ...
        'Hittest'           , 'off');
    hold on
    
    obj.SImgs.hContextBG = image(...
        'CData'             , repmat(obj.dBGCOLOR(1) + 0.02.*rand(1400, 1), [1, 2, 3]), ...
        'XData'             , [1, 64], ...
        'YData'             , [1, 1400], ...
        'AlphaData'         , 0.8);
    
    % ---------------------------------------------------------------------
    
    
    % ---------------------------------------------------------------------
    % Load the icons of the menubar, menubar and sidebar and context menu
    for iI = 1:length(obj.SMenu)
        
        hParent = obj.SAxes.hMenu;
        if obj.SMenu(iI).SubGroupInd
            hParent = obj.SAxes.hContext;
        else
            if obj.SMenu(iI).GroupIndex == 255, hParent = obj.SAxes.hTools; end
            if obj.SMenu(iI).GroupIndex == 256, hParent = obj.SSidebar.hIcons; end
        end
                
        obj.SImgs.hIcons(iI)  = image(...
            'Parent'        , hParent, ...
            'CData'         , 1, ...
            'AlphaData'     , 1);
    end
    % ---------------------------------------------------------------------
    
    
    % ---------------------------------------------------------------------
    % Create the remaining sidebar elements
    obj.SSidebar.hAxes = axes(...
        'Parent'            , obj.SSidebar.hPanel, ...
        'Position'          , [10, 20*(iI + 1) + 15, 230, 180], ...
        'Units'             , 'pixels', ...
        'Color'             , 'k', ...
        'XColor'            , obj.dBGCOLOR, ...
        'YColor'            , obj.dBGCOLOR, ...
        'XTickMode'         , 'manual', ...
        'YTickMode'         , 'manual', ...
        'YDir'              , 'reverse', ...
        'Box'               , 'on', ...
        'XGrid'             , 'on', ...
        'YGrid'             , 'on');
    
    obj.SSidebar.hImg = image(...
        'CData'                     ,permute(obj.dBGCOLOR/2, [1 3 2]), ...
        'HitTest'                   , 'off');
    
    obj.SSidebar.hPatch = patch(0, 0, [120 138 161]/255);
    
    for iI = 1:length(obj.SSliders)
        obj.SSliders(iI).hText = uicontrol(...
            'Parent'                , obj.SSidebar.hPanel, ...
            'Style'                 , 'text', ...
            'Position'              , [10, 20*iI - 15, 120, 20], ...
            'String'                , obj.SSliders(iI).Name, ...
            'ForegroundColor'       , 'w', ...
            'BackgroundColor'       , obj.dBGCOLOR, ...
            'HorizontalAlignment'   , 'left', ...
            'FontSize'              , 12, ...
            'Hittest'               , 'off');
        obj.SSliders(iI).hAxes = axes(...
            'Parent'                , obj.SSidebar.hPanel, ...
            'Units'                 , 'pixels', ...
            'Position'              , [130, 20*iI - 8, 100, 10]);
        obj.SSliders(iI).hScatter = scatter(obj.SSliders(iI).Def, 0.5, 100, 'v', 'filled', ...
            'Parent'                , obj.SSliders(iI).hAxes, ...
            'MarkerFaceColor'       , 'w', ...
            'MarkerEdgeColor'       , [0.8 0.8 0.8], ...
            'Hittest'               , 'off');
        set(obj.SSliders(iI).hAxes, ...
            'Color'                 , obj.dBGCOLOR, ...
            'XColor'                , [0.8 0.8 0.8], ...
            'XLim'                  , obj.SSliders(iI).Lim, ...
            'XTick'                 , obj.SSliders(iI).Tick, ...
            'XScale'                , obj.SSliders(iI).Scale, ...
            'XTickLabel'            , {}, ...
            'YLim'                  , [-1 1]);
    end
    % ---------------------------------------------------------------------
    
    
    % ---------------------------------------------------------------------
    % The utility axis
    obj.SAxes.hUtil = axes(...
        'Parent'                , obj.hF, ...
        'Visible'               , 'off', ...
        'Units'                 , 'pixels', ...
        'Position'              , [1 1 1 1], ...
        'YDir'                  , 'reverse', ...
        'Hittest'               , 'off', ...
        'Visible'               , 'off');
    obj.SImgs.hUtil = image(...
        'Parent'                , obj.SAxes.hUtil, ...
        'CData'                 , 0, ...
        'Visible'               , 'off');
    % -------------------------------------------------------------------------
    
    
    % -------------------------------------------------------------------------
    % Create the tooltip text element
    obj.STooltip.hAxes = axes(...
        'Units'                 , 'pixels', ...
        'YDir'                  , 'reverse', ...
        'Visible'               , 'off', ...
        'Hittest'               , 'off');
    obj.STooltip.hImg = image(...
        'CData'                 , 1, ...
        'Visible'               , 'off', ...
        'HitTest'               , 'on');
    obj.STooltip.hText = text(75, 22, '', ...
        'HorizontalAlignment'   , 'center', ...
        'Color'                 , [1 0.9 0.6], ...
        'FontSize'              , 18, ...
        'FontName'              , 'Aleo', ...
        'FontWeight'            , 'bold', ...
        'Hittest'               , 'on');
    % -------------------------------------------------------------------------

    
    % -------------------------------------------------------------------------
    % Determine the number of views
%     if obj.iViews
%         iViews = obj.iViews;
%     else
%         iNumImages = max(1, length(obj.cMapping));
%         dRoot = sqrt(iNumImages);
%         iPanelsN = ceil(dRoot);
%         iPanelsM = ceil(dRoot);
%         while iPanelsN*iPanelsM >= iNumImages
%             iPanelsN = iPanelsN - 1;
%         end
%         iPanelsN = iPanelsN + 1;
%         iPanelsN = min([4, iPanelsN]);
%         iPanelsM = min([4, iPanelsM]);
%         iViews = [iPanelsN, iPanelsM];
%     end
%     
%     if l3DMode
%         lInd = strcmp({obj.SMenu.Name}, '2d');
%         obj.SMenu(lInd).Active = true;
%         iN = max(1, min([6, length(obj.SData) - obj.iStartSeries + 1, prod(obj.iViews)]));
%         obj.setViews(3, iN);
%         obj.iViews = iViews;
%     else
%         obj.setViews(iViews);
%     end
    % -------------------------------------------------------------------------
    
catch me
    delete(obj.hF);
    delete(obj);
    rethrow(me);
end






%     obj.SMenus.SView.hEqualize = uimenu(obj.SMenus.hView, 'Label', 'Reset Tile Sizes', 'Callback', @obj.contextMenu);
%     obj.SMenus.SView.hOverlay = uimenu(obj.SMenus.hView, 'Label', 'Overlay', 'Callback', @obj.contextMenu);
%     
%     obj.SMenus.hExport1    = uimenu(obj.SMenus.hContext, 'Label', 'Export to Workspace', 'Separator', 'on', 'Callback', @obj.contextMenu);
%     obj.SMenus.hExport2    = uimenu(obj.SMenus.hContext, 'Label', 'Export to File', 'Separator', 'on', 'Callback', @obj.contextMenu);
%     
%     obj.SMenus.hOverlay    = uimenu(obj.SMenus.hContext, 'Label', 'Set Overlay', 'Callback', @obj.contextMenu);
%     obj.SMenus.hSplit      = uimenu(obj.SMenus.hContext, 'Label', 'Split', 'Callback', @obj.contextMenu);
%     obj.SMenus.hReslice    = uimenu(obj.SMenus.hContext, 'Label', 'Reslice', 'Callback', @obj.contextMenu);


function [iPosition, l3DMode] = fGetDefaults(obj)

sMFilePath = [fileparts(mfilename('fullpath')), filesep];

% -------------------------------------------------------------------------
% Read the preferences from the save file and determine figure size

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Default size: 100 px border to screen edges
iScreenSize = get(0, 'ScreenSize');
iPosition(1:2) = 200;
iPosition(3:4) = iScreenSize(3:4) - 400;

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read saved preferences from file
l3DMode = 0;
csSaveVars = {'sPath', 'iSidebarWidth', 'lRuler', 'dGrid', 'iIconSize'};
if exist([sMFilePath, 'imagineSave.mat'], 'file')
    load([sMFilePath, filesep, 'imagineSave.mat']);
    
    iPosition           = S.iPosition;
%     l3DMode             = S.l3DMode;
    
    for iI = 1:length(csSaveVars)
        if isfield(S, csSaveVars{iI})
            obj.(csSaveVars{iI}) = S.(csSaveVars{iI});
        end
    end
    
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % Make sure the figure fits on the screen
    if (iPosition(1) + iPosition(3) > iScreenSize(3)) || (iPosition(2) + iPosition(4) > iScreenSize(4))
        iPosition(1:2) = 200;
        iPosition(3:4) = iScreenSize(3:4) - 400;
    end
    if S.lDocked, iPosition = []; end
end
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% Read the menu and slider definitions
S = load([sMFilePath, filesep, 'MenuSlider.mat']);
obj.SMenu = S.SMenu;
obj.SSliders = S.SSliders;
% -------------------------------------------------------------------------

if ~obj.lWIP
    obj.SMenu = obj.SMenu(~[obj.SMenu.WIP]);
end
