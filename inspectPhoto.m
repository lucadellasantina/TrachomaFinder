%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%
%  This file is part of Follicle Finder
%
%  Follicle Finder is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <https://www.gnu.org/licenses/>.
%

function Dots = inspectPhoto(Img, Dots, Prefs)
    Ir = Img(:,:,1);
    Ig = Img(:,:,2);
    Ib = Img(:,:,3);
    
    % Default parameter values
    CutNumVox   = ceil(size(Img)/Prefs.Zoom); % Size of zoomed region    
    PosMouse    = [0,0]; % mouse pointer position in screen coordinates
    Pos         = [ceil(size(Img,2)/2), ceil(size(Img,1)/2)]; %  mouse position in image coordinates
    PosRect     = [ceil(size(Img,2)/2-CutNumVox(2)/2), ceil(size(Img,1)/2-CutNumVox(1)/2)]; % Initial position of zoomed rectangle (top-left vertex)
    PosZoom     = [-1, -1]; % Mouse position inside the zoomed area
	click       = false;    % Initialize click status
    if contains(Prefs.Type, 'Eyelid') && ~isempty(Dots.Filter)
        SelObjID = 1;
    else        
        SelObjID = 0;        % Initialize selected object ID#
    end
    actionType  = Prefs.actionType; % Mode of operation
    analysisDone= false;    % Flag to determine if we should close the UI
	
	% Initialize GUI Figure window
    Title = 'Photo inspector (use right panel to define regions)';
    if isfield(Prefs, 'Title')
        Title = [Title ', ' Prefs.Title];
    end
    
	% Initialize GUI Figure window
	fig_handle = figure('Name', Title,'NumberTitle','off','Color',[.3 .3 .3], 'MenuBar','none', 'Units','norm', ...
		'WindowButtonDownFcn',@button_down, 'WindowButtonUpFcn',@button_up, 'WindowButtonMotionFcn', @on_click, 'KeyPressFcn', @key_press,'windowscrollWheelFcn', @wheel_scroll, 'CloseRequestFcn', @closeRequest);

    % Add GUI conmponents
    set(gcf,'units', 'normalized', 'position', [0.05 0.1 0.90 0.76]);
    pnlSettings     = uipanel(  'Title',''          ,'Units','normalized','Position',[.903,.005,.095,.99]); %#ok, unused variable
    txtValidObjs    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.960,.085,.02],'String',['Total: ' num2str(numel(find(Dots.Filter)))]);
    txtAction       = uicontrol('Style','text'      ,'Units','normalized','position',[.912,.925,.020,.02],'String','Tool:'); %#ok, unused handle
    if contains(Prefs.Type, 'Eyelid')
        cmbAction   = uicontrol('Style','popup'     ,'Units','normalized','Position',[.935,.910,.055,.04],'String', {'Refine (r)', 'Enclose(e)'},'Callback', @cmbAction_changed);
    elseif contains(Prefs.Type, 'Follicles')
        cmbAction   = uicontrol('Style','popup'     ,'Units','normalized','Position',[.935,.910,.055,.04],'String', {'Add (a)', 'Refine (r)','Select (s)', 'Enclose(e)', 'Magic wand(m)'},'Callback', @cmbAction_changed);
    end
    chkShowObjects  = uicontrol('Style','checkbox'  ,'Units','normalized','position',[.912,.890,.085,.02],'String','Show (spacebar)', 'Value',1,'Callback',@chkShowObjects_changed);
    lstDots         = uicontrol('Style','listbox'   ,'Units','normalized','position',[.907,.710,.085,.15],'String',[],'Callback',@lstDots_valueChanged);
    if contains(Prefs.Type, 'Follicles')
        txtZoom     = uicontrol('Style','text'      ,'Units','normalized','position',[.925,.430,.050,.02],'String','Zoom level:'); %#ok, unused variable
        btnZoomOut  = uicontrol('Style','Pushbutton','Units','normalized','position',[.920,.370,.030,.05],'String','-','Callback',@btnZoomOut_clicked); %#ok, unused variable
        btnZoomIn   = uicontrol('Style','Pushbutton','Units','normalized','position',[.950,.370,.030,.05],'String','+','Callback',@btnZoomIn_clicked); %#ok, unused variable
        btnScores   = uicontrol('Style','Pushbutton','Units','normalized','position',[.905,.330,.090,.03],'String','Trachoma scoring', 'Callback', @btnScores_clicked); %#ok, unused variable
        cmbScoreF   = uicontrol('Style','popup'     ,'Units','normalized','Position',[.910,.280,.025,.04],'String', {'F0','F1','F2','F3'}, 'Callback',@cmbScoreF_changed);
        cmbScoreP   = uicontrol('Style','popup'     ,'Units','normalized','Position',[.940,.280,.025,.04],'String', {'P0','P1','P2','P3'}, 'Callback',@cmbScoreP_changed);
        cmbScoreC   = uicontrol('Style','popup'     ,'Units','normalized','Position',[.970,.280,.025,.04],'String', {'C0','C1','C2','C3'}, 'Callback',@cmbScoreC_changed);
        cmbScoreTE  = uicontrol('Style','popup'     ,'Units','normalized','Position',[.915,.235,.030,.04],'String', {'T/E0','T/E1','T/E2','T/E3'}, 'Callback',@cmbScoreTE_changed);
        cmbScoreCC  = uicontrol('Style','popup'     ,'Units','normalized','Position',[.955,.235,.030,.04],'String', {'CC0','CC1','CC2','CC3'}, 'Callback',@cmbScoreCC_changed);
        txtDiagnosis= uicontrol('Style','text'      ,'Units','normalized','position',[.905,.205,.090,.02],'String','Trachoma Diagnosis:'); %#ok, unused variable
        lstDiagnosis= uicontrol('Style','listbox'   ,'Units','normalized','Position',[.907,.080,.085,.12],'String', {'TNormal','TF','TI', 'TF+TI','TS','TT','CO', 'Ungradable'}, 'max', 1, 'Min', 1 ,'Callback', @lstDiagnosis_changed);
    end
    btnSave         = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.020,.088,.05],'String','Done','Callback',@btnSave_clicked); %#ok, unused variable
    
    % Selected object info
    btnDelete       = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.660,.088,.04],'String','Delete Item (d)','Callback',@btnDelete_clicked); %#ok, unused variable
    txtSelObj       = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.630,.085,.02],'String','Selected item'); %#ok, unused variable
    txtSelObjID     = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.600,.085,.02],'String','ID# :');
    txtSelObjPos    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.570,.085,.02],'String','Pos : ');
    txtSelObjPix    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.540,.085,.02],'String','Pixels : ');
    txtSelObjValid  = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.510,.085,.02],'String','Type : ');    
    if contains(Prefs.Type, 'Follicles')
        btnValidate = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.460,.088,.04],'String','Change validation (v)','Callback',@btnValidate_clicked); %#ok, unused variable
    end
    
    % Main drawing area and related handles
	axes_handle     = axes('Position', [0 0 0.903 1]);
	frame_handle    = 0;
    rect_handle     = 0;
    brushSize       = 20;
    brush           = rectangle(axes_handle,'Curvature', [1 1],'EdgeColor', [1 1 0],'LineWidth',2,'LineStyle','-');
    animatedLine    = animatedline('LineWidth', 1, 'Color', 'blue');
    
    cmbAction_assign(actionType);
    if contains(Prefs.Type, 'Follicles')        
        cmbScoreF_assign(Dots.Scores.F);
        cmbScoreP_assign(Dots.Scores.P);
        cmbScoreC_assign(Dots.Scores.C);
        cmbScoreTE_assign(Dots.Scores.TE);
        cmbScoreCC_assign(Dots.Scores.CC);
        lstDiagnosis_assign(Dots.Diagnosis);    
    end
    lstDotsRefresh;   % List all objects and refresh image
    uiwait;           % The GUI waits for user interaction as default state 
    
    function closeRequest(src,event) %#ok unused parameters
        % Close the GUI and return detected objects
        if ~analysisDone
            Dots = [];
        end
        delete(fig_handle);
    end

    function btnSave_clicked(src, event)
        % Trigger closure of the GUI and return detected objects
        analysisDone = true;
        closeRequest(src,event);
    end

    function btnScores_clicked(~, ~)
        info        = {'## Scoring notation:'};
        info{end+1} = ' ';
        info{end+1} = 'Follices (hallmark of TF):';
        info{end+1} = 'F0 = No follicles, F1 = 1-4 follicles';      
        info{end+1} = 'F2 = 5-9 follicles F3 = 10+ follicles';      
        info{end+1} = ' ';
        info{end+1} = 'Papillary hypertrophy and diffused infiltration (hallmark of TI):';
        info{end+1} = 'P0 = No papillae, P1 = some papillae';      
        info{end+1} = 'P2 = up to half vessels hazy P3 = half+ vessels hazy due to inflammation';      
        info{end+1} = ' ';
        info{end+1} = 'Conjunctival scarring (hallmark of TS)';
        info{end+1} = 'C0 = No scarring, C1 = some hard to see scars';              
        info{end+1} = 'C2 = easily visible scars C3 = sheets of scarring';              
        info{end+1} = ' ';
        info{end+1} = 'Trichiasis/entropion (hallmark of TT):';
        info{end+1} = 'TE0 = Normal eyelid, TE1 = abnormal eyelash';              
        info{end+1} = 'TE2 = eyelash touching cornea TE3 = eyelid turned inward';              
        info{end+1} = ' ';
        info{end+1} = 'Corneal opacity (hallmark of CO)';        
        info{end+1} = 'CO0 = Normal cornea, CO1 = opacity ouside pupil';              
        info{end+1} = 'CO2 = opacity partially over pupil CO3 = opacity over pupil';              
        info{end+1} = ' ';
        info{end+1} = '## Diagnosis notation:';        
        info{end+1} = ' ';
        info{end+1} = 'TNormal = Absence of hallmarks to positively diagnose trachoma';
        info{end+1} = 'TF = Tracomatous Inflammation - Follicular';
        info{end+1} = 'TI = Trachomatous inflammation - Intense';
        info{end+1} = 'TF+TI = combination of the two above';
        info{end+1} = 'TS = Trachomatous scarring';
        info{end+1} = 'TT = Trachomatous trichiasis';
        info{end+1} = 'CO = Corneal opacity';

        CreateStruct.Interpreter = 'tex';
        CreateStruct.WindowStyle = 'modal';
        msgbox(info, 'Trachoma scoring info', CreateStruct);
    end

    function cmbAction_changed(src,event) %#ok, unused parameters
        if contains(Prefs.Type, 'Eyelid')
            switch get(src,'Value')
                case 1, actionType = 'Refine';
                case 2, actionType = 'Enclose';
            end
        elseif contains(Prefs.Type, 'Follicles')
            switch get(src,'Value')
                case 1, actionType = 'Add';                
                case 2, actionType = 'Refine';
                case 3, actionType = 'Select';
                case 4, actionType = 'Enclose';
                case 5, actionType = 'MagicWand';
            end
        end
    end

    function cmbAction_assign(newType)
        if contains(Prefs.Type, 'Eyelid')
            switch newType
                case 'Refine',      set(cmbAction, 'Value', 1);
                case 'Enclose',     set(cmbAction, 'Value', 2);
            end        
        elseif contains(Prefs.Type, 'Follicles')
            switch newType
                case 'Add',         set(cmbAction, 'Value', 1);                
                case 'Refine',      set(cmbAction, 'Value', 2);
                case 'Select',      set(cmbAction, 'Value', 3);
                case 'Enclose',     set(cmbAction, 'Value', 4);
                case 'MagicWand',   set(cmbAction, 'Value', 5);
            end        
        end
    end

    function cmbScoreF_changed(src, event) %#ok, unused parameters
        Dots.Scores.F = get(src, 'Value')-1;
    end
    function cmbScoreP_changed(src, event) %#ok, unused parameters
        Dots.Scores.P = get(src, 'Value')-1;
    end
    function cmbScoreC_changed(src, event) %#ok, unused parameters
        Dots.Scores.C = get(src, 'Value')-1;
    end
    function cmbScoreTE_changed(src, event) %#ok, unused parameters
        Dots.Scores.TE = get(src, 'Value')-1;
    end
    function cmbScoreCC_changed(src, event) %#ok, unused parameters
        Dots.Scores.CC = get(src, 'Value')-1;
    end

    function cmbScoreF_assign(newScore)
        switch newScore
            case 0, set(cmbScoreF, 'Value', 1);                
            case 1, set(cmbScoreF, 'Value', 2);
            case 2, set(cmbScoreF, 'Value', 3);
            case 3, set(cmbScoreF, 'Value', 4);
        end
    end
    function cmbScoreP_assign(newScore)
        switch newScore
            case 0, set(cmbScoreP, 'Value', 1);                
            case 1, set(cmbScoreP, 'Value', 2);
            case 2, set(cmbScoreP, 'Value', 3);
            case 3, set(cmbScoreP, 'Value', 4);
        end
    end
    function cmbScoreC_assign(newScore)
        switch newScore
            case 0, set(cmbScoreC, 'Value', 1);                
            case 1, set(cmbScoreC, 'Value', 2);
            case 2, set(cmbScoreC, 'Value', 3);
            case 3, set(cmbScoreC, 'Value', 4);
        end
    end
    function cmbScoreTE_assign(newScore)
        switch newScore
            case 0, set(cmbScoreTE, 'Value', 1);                
            case 1, set(cmbScoreTE, 'Value', 2);
            case 2, set(cmbScoreTE, 'Value', 3);
            case 3, set(cmbScoreTE, 'Value', 4);
        end
    end
    function cmbScoreCC_assign(newScore)
        switch newScore
            case 0, set(cmbScoreCC, 'Value', 1);                
            case 1, set(cmbScoreCC, 'Value', 2);
            case 2, set(cmbScoreCC, 'Value', 3);
            case 3, set(cmbScoreCC, 'Value', 4);
        end
    end

    function lstDiagnosis_changed(src, event) %#ok, unused parameters
        % Update diagnosis
        lstDiagNames = get(src, 'String'); 
        newDiagValue = get(src, 'Value');
        
        % One diagnosis: store as char, multiple diagn:store as cell array        
        Dots.Diagnosis = lstDiagNames{newDiagValue};
    end

    function lstDiagnosis_assign(newDiagnosis)
        % Populate with all new diagnoses
        switch newDiagnosis
            case 'TNormal',     newValue = 1;
            case 'TF',          newValue = 2;
            case 'TI',          newValue = 3;
            case 'TF+TI',       newValue = 4;
            case 'TS',          newValue = 5;
            case 'TT',          newValue = 6;
            case 'CO',          newValue = 7;
            case 'Ungradable',  newValue = 8;
        end
        set(lstDiagnosis, 'Value', newValue);       
    end

    function lstDots_valueChanged(src,event) %#ok, unused arguments
        % Update on-screen info of selected object        
        SelObjID = get(src, 'Value');
        
        if SelObjID > 0 && numel(Dots.Filter)>0
            set(txtSelObjID ,'string',['ID#: ' num2str(SelObjID)]);
            set(txtSelObjPos,'string',['Pos X:' num2str(Dots.Pos(SelObjID,1)) ', Y:' num2str(Dots.Pos(SelObjID,2))]);
            set(txtSelObjPix,'string',['Pixels : ' num2str(numel(Dots.Vox(SelObjID).Ind))]);
            switch Dots.Filter(SelObjID)
                case 1,  set(txtSelObjValid ,'string','Type : True');
                case -1, set(txtSelObjValid ,'string','Type : False');
                case 0,  set(txtSelObjValid ,'string','Type : Maybe');
            end
        else
            set(txtSelObjID    ,'string','ID#: ');
            set(txtSelObjPos   ,'string','Pos : ');
            set(txtSelObjPix   ,'string','Pixels : ');
            set(txtSelObjValid ,'string','Type : ');
        end

        % Store Zoom rectangle verteces coodinates (clockwise from top-left)
        Rect(1,:) = [PosRect(1), PosRect(2)];
        Rect(2,:) = [PosRect(1)+CutNumVox(2), PosRect(2)];
        Rect(3,:) = [PosRect(1)+CutNumVox(2), PosRect(2)+CutNumVox(1)];
        Rect(4,:) = [PosRect(1), PosRect(2)+CutNumVox(1)];

        if SelObjID > 0 && ~inpolygon_fast(Dots.Pos(SelObjID,1), Dots.Pos(SelObjID,2),Rect(:,1), Rect(:,2))
            Pos = [Dots.Pos(SelObjID,1), Dots.Pos(SelObjID,2)];
            % Ensure new position is within boundaries of the image
            Pos     = [max(Pos(1),CutNumVox(2)/2), max(Pos(2), CutNumVox(1)/2)];
            Pos     = [min(Pos(1),size(Img,2)-CutNumVox(2)/2), min(Pos(2), size(Img,1)-CutNumVox(1)/2)];
            PosRect = [Pos(1)-CutNumVox(2)/2, Pos(2)-CutNumVox(1)/2];
            PosZoom = [-1 -1];
            refreshBothPanels;
        else
            refreshRightPanel;
        end
    end

    function btnDelete_clicked(src,event) %#ok, unused arguments
        % Remove selected object from the list
        if SelObjID > 0
            Dots.Pos(SelObjID, :) = [];
            Dots.Vox(SelObjID)    = [];
            Dots.Filter(SelObjID) = [];

            if SelObjID > numel(Dots.Filter)
                SelObjID = numel(Dots.Filter);
                set(lstDots, 'Value', 1);
            end
            PosZoom = [-1, -1];
            lstDotsRefresh;            
            refreshRightPanel;    
        end
    end

    function btnValidate_clicked(src,event) %#ok, unused arguments
        % Change the validation status of selected object        
        if SelObjID > 0
            switch Dots.Filter(SelObjID)
                case 0, Dots.Filter(SelObjID)  = 1;  % Switch to True
                case 1, Dots.Filter(SelObjID)  = -1; % Switch to False
                case -1, Dots.Filter(SelObjID) = 0;  % Switch to Maybe
            end
            
            set(lstDots, 'Value', SelObjID);
            lstDots_valueChanged(lstDots, event);
            PosZoom = [-1, -1];
            refreshRightPanel;    
        end
    end

    function lstDotsRefresh
        % Updates list of available Objects (Objects are ROIs in the image)
        set(lstDots, 'String', 1:numel(Dots.Filter));
        set(txtValidObjs,'string',['Total: ' num2str(numel(find(Dots.Filter)))]);
        
        if SelObjID > 0 && SelObjID <= numel(Dots.Filter)            
            PosZoom = [Dots.Pos(SelObjID, 2), Dots.Pos(SelObjID, 1)];
            set(lstDots, 'Value', SelObjID);
            lstDots_valueChanged(lstDots, []);
            
        elseif SelObjID > numel(Dots.Filter)
            SelObjID = numel(Dots.Filter);
            set(lstDots, 'Value', SelObjID);
            disp('dot was out of range');
        end
        
        refreshRightPanel;
    end

    function ID = addDot(X, Y, D)
        % Creates a new object #ID from pixels within R radius
        % X,Y: center coordinates, R: radius in zoomed region pixels 
        
        % Convert radius from zoomed to image units region scaling factor
        ZoomFactor = size(Img,1) / CutNumVox(1);
        r = D / ZoomFactor /2;
        
        % Create a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = (x-X).^2 + (y-Y).^2 < r^2;
        
        % Generate statistics of the new dot and add to Dots
        if isempty(Dots.Pos)
            Dots.Pos(1,:)       = [X,Y];            
            Dots.Vox(1).Ind     = find(mask);
            [Dots.Vox(1).Pos(:,1), Dots.Vox(1).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(1).Ind);            
            Dots.Filter         = 1;
        else
            Dots.Pos(end+1,:)   = [X,Y];
            Dots.Vox(end+1).Ind = find(mask);
            [Dots.Vox(end).Pos(:,1), Dots.Vox(end).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(end).Ind);            
            Dots.Filter(end+1)  = 1;
        end 
                
        SelObjID = numel(Dots.Filter);
        ID = SelObjID;

        % Extract raw brightness levels (R,G,B) for each masked pixel
        if contains(Prefs.Type, 'Follicles')
            % Dots.Vox(ID).RawBright = uint8(impixel(Img, Dots.Vox(ID).Pos(:,2), Dots.Vox(ID).Pos(:,1)));
            Dots.Vox(ID).RawBright = Ir(Dots.Vox(ID).Ind);
            Dots.Vox(ID).RawBright(:,2) = Ig(Dots.Vox(ID).Ind);
            Dots.Vox(ID).RawBright(:,3) = Ib(Dots.Vox(ID).Ind);
        end
        lstDotsRefresh;
    end

    function ID = addDotMagicWand(X, Y, D)
        % Creates a new object #ID from pixels within R radius
        % X,Y: center coordinates, R: radius in zoomed region pixels 

        oldPointer = get(fig_handle, 'Pointer');
        set(fig_handle, 'Pointer', 'watch'); pause(0.3);
        
        % Convert radius from zoomed to image units region scaling factor
        ZoomFactor = size(Img,1) / CutNumVox(1);
        r = D / ZoomFactor /2;
        
        % Create a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = (x-X).^2 + (y-Y).^2 < r^2;

        % Use pixels within circle as reference for the magic wand
        ind = find(mask);
        [lstX, lstY] = ind2sub(size(Img),ind);
        mask = magicwand2(Img, 10, lstX, lstY); 
        
        % Generate statistics of the new dot and add to Dots
        if isempty(Dots.Pos)
            Dots.Pos(1,:)       = [X,Y];            
            Dots.Vox(1).Ind     = find(mask);
            [Dots.Vox(1).Pos(:,1), Dots.Vox(1).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(1).Ind);            
            Dots.Filter         = 1;
        else
            Dots.Pos(end+1,:)   = [X,Y];
            Dots.Vox(end+1).Ind = find(mask);
            [Dots.Vox(end).Pos(:,1), Dots.Vox(end).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(end).Ind);            
            Dots.Filter(end+1)  = 1;
        end 
                
        SelObjID = numel(Dots.Filter);
        ID = SelObjID;

        % Extract raw brightness levels (R,G,B) for each masked pixel
        if contains(Prefs.Type, 'Follicles')
            %Dots.Vox(ID).RawBright = uint8(impixel(Img, Dots.Vox(ID).Pos(:,2), Dots.Vox(ID).Pos(:,1)));
            Dots.Vox(ID).RawBright = Ir(Dots.Vox(ID).Ind);
            Dots.Vox(ID).RawBright(:,2) = Ig(Dots.Vox(ID).Ind);
            Dots.Vox(ID).RawBright(:,3) = Ib(Dots.Vox(ID).Ind);            
        end
        lstDotsRefresh;
        
        set(fig_handle, 'Pointer', oldPointer);        
    end

    function addPxToDot(X, Y, R, ID)
        % Adds pixels within R radius to object #ID
        % X,Y: center coordinates, R: radius in zoomed region pixels 
        
        % Convert radius from zoomed to image units region scaling factor
        scaling = size(Img,1)/CutNumVox(1);
        r = R/scaling/2;
        
        mask = [];
        % Convolve a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        for i = 1:numel(X)
            if i==1
                mask = (x-X(i)).^2 + (y-Y(i)).^2 < r.^2;
            else
                mask = mask | (x-X(i)).^2 + (y-Y(i)).^2 < r.^2;
            end
        end

        % Add new pixels to those belonging to Dot #ID
        if ID > 0 && ~isempty(mask)
            Dots.Vox(ID).Ind = union(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = [];
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            

            % Extract raw brightness levels (R,G,B) for each masked pixel
            if contains(Prefs.Type, 'Follicles')            
                %Dots.Vox(ID).RawBright = uint8(impixel(Img, Dots.Vox(ID).Pos(:,2), Dots.Vox(ID).Pos(:,1))); 
                Dots.Vox(ID).RawBright = Ir(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,2) = Ig(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,3) = Ib(Dots.Vox(ID).Ind);                
            end
        end
    end

    function addPolyAreaToDot(xv, yv, ID)
        % Adds all pixels within area of passed polygon to object #ID
        % xv,yv: coordinates of the polygon vertices
        % ID: object number to which add the pixels

        if numel(xv)<2
            return
        end
        
        % Switch mouse pointer to hourglass while computing
        oldPointer = get(fig_handle, 'Pointer');
        set(fig_handle, 'Pointer', 'watch'); pause(0.3);

        % Create mask inside the passed polygon coordinates
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask   = inpolygon_fast(x,y,xv,yv); % faster implementation, ~75x
        
        % Add new pixels to those belonging to Dot #ID
        if ID == 0
            ID = addDot(ceil(mean(xv)),ceil(mean(yv)),5);
        end
        
        if ID > 0
            Dots.Vox(ID).Ind = union(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = zeros(numel(Dots.Vox(ID).Ind), 2);
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            

            % Extract raw brightness levels (R,G,B) for each masked pixel
            if contains(Prefs.Type, 'Follicles')
                %Dots.Vox(ID).RawBright = uint8(impixel(Img, Dots.Vox(ID).Pos(:,2), Dots.Vox(ID).Pos(:,1)));
                Dots.Vox(ID).RawBright = Ir(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,2) = Ig(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,3) = Ib(Dots.Vox(ID).Ind);                
            end
        end 
        
        set(fig_handle, 'Pointer', oldPointer);
    end

    function removePxFromDot(X, Y, R, ID)
        % Removes pixels within R radius from object #ID
        % X,Y: center coordinates, R: radius in zoomed region pixels 
        
        % Convert radius from zoomed to image units region scaling factor
        scaling = size(Img,1)/CutNumVox(1);
        r = R/scaling/2;
        
        % Convolve a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        for i = 1:numel(X)
            if i==1
                mask = (x-X(i)).^2 + (y-Y(i)).^2 < r.^2;
            else
                mask = mask | (x-X(i)).^2 + (y-Y(i)).^2 < r.^2;
            end
        end

        % Pixels flagged in mask from those belonging to Dot #ID
        if ID > 0
            Dots.Vox(ID).Ind = setdiff(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = [];
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            

            % Extract raw brightness levels (R,G,B) for each masked pixel
            if contains(Prefs.Type, 'Follicles')
                % Dots.Vox(ID).RawBright = uint8(impixel(Img, Dots.Vox(ID).Pos(:,2), Dots.Vox(ID).Pos(:,1)));
                Dots.Vox(ID).RawBright = Ir(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,2) = Ig(Dots.Vox(ID).Ind);
                Dots.Vox(ID).RawBright(:,3) = Ib(Dots.Vox(ID).Ind);                
            end
        end        
    end

    function chkShowObjects_changed(src,event) %#ok, unused arguments
        refreshRightPanel;
    end

    function btnZoomOut_clicked(src, event) %#ok, unused arguments
        ImSize      = [size(Img,1), size(Img,2)];
        CutNumVox   = [min(CutNumVox(1)*2, ImSize(1)), min(CutNumVox(2)*2, ImSize(2))];
        PosRect     = [max(1,Pos(1)-CutNumVox(2)/2), max(1,Pos(2)-CutNumVox(1)/2)];
        PosZoom     = [-1, -1];
        refreshBothPanels;
    end

    function btnZoomIn_clicked(src, event) %#ok, unused arguments
        CutNumVox   = [max(round(CutNumVox(1)/2,0), 32), max(round(CutNumVox(2)/2,0),32)];
        PosRect     = [max(1,Pos(1)-CutNumVox(2)/2), max(1,Pos(2)-CutNumVox(1)/2)];
        PosZoom     = [-1, -1];
        refreshBothPanels;
    end

    function wheel_scroll(~, event)
        switch actionType
            case {'Add', 'Refine', 'MagicWand'}
                
                if event.VerticalScrollCount < 0
                    brushSize = brushSize +1;
                elseif event.VerticalScrollCount > 0
                    brushSize = brushSize -1;
                end
                
                if brushSize < 1
                    brushSize = 1;
                end
                
                % Adjust brush to the new size and redraw it onscreen
                ZoomFactor = size(Img,1) / CutNumVox(1);                
                brushSizeScaled = brushSize * ZoomFactor;
                PosXfenced = max(brushSizeScaled/2, min(PosMouse(1)-brushSizeScaled/2, size(Img,2)*2-brushSizeScaled-2));
                PosYfenced = max(brushSizeScaled/2, min(PosMouse(2)-brushSizeScaled/2, size(Img,1)*2-brushSizeScaled-2));
                brushPos = [PosXfenced, PosYfenced, brushSizeScaled, brushSizeScaled];
                
                if ~isvalid(brush)
                    brush = rectangle(axes_handle,'Position', brushPos,'Curvature',[1 1],'EdgeColor',[1 1 0],'LineWidth',2,'LineStyle','-');
                else
                    set(brush, 'Position',  brushPos);
                end
                click = false;
        end
    end
    
    function key_press(src, event) %#ok missing parameters
        switch event.Key  % Process shortcut keys
            case 'space'
                chkShowObjects.Value = ~chkShowObjects.Value;
                chkShowObjects_changed();
            case 'a'
                set(cmbAction, 'Value', 1); 
                cmbAction_changed(cmbAction, event);
            case 'r'
                set(cmbAction, 'Value', 2); 
                cmbAction_changed(cmbAction, event);
            case 's'
                set(cmbAction, 'Value', 3); 
                cmbAction_changed(cmbAction, event);
            case 'e'
                set(cmbAction, 'Value', 4); 
                cmbAction_changed(cmbAction, event);
            case 'm'
                set(cmbAction, 'Value', 5); 
                cmbAction_changed(cmbAction, event);
            case 'd'
                btnDelete_clicked();
            case {'leftarrow'}
                Pos = [max(CutNumVox(2)/2, Pos(1)-CutNumVox(1)+ceil(CutNumVox(2)/5)), Pos(2)];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'rightarrow'}
                Pos = [min(size(Img,2)-1-CutNumVox(2)/2, Pos(1)+CutNumVox(2)-ceil(CutNumVox(2)/5)), Pos(2)];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'uparrow'}
                Pos = [Pos(1), max(CutNumVox(1)/2, Pos(2)-CutNumVox(1)+ceil(CutNumVox(1)/5))];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'downarrow'}
                Pos = [Pos(1), min(size(Img,1)-1-CutNumVox(1)/2, Pos(2)+CutNumVox(1)-ceil(CutNumVox(1)/5))];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case 'equal' , btnZoomIn_clicked;
            case 'hyphen', btnZoomOut_clicked;
        end
    end

	%mouse handler
	function button_down(src, event)   
        click = true;
        on_click(src,event);
	end

	function button_up(src, event)  %#ok, unused arguments
		click       = false;
        click_point = get(gca, 'CurrentPoint');
        MousePosX   = ceil(click_point(1,1));

        switch actionType
            case {'Enclose'}
                if MousePosX > size(Img,2)
                    [x,y] = getpoints(animatedLine);

                    % Locate position of points in respect to zoom area
                    PosZoomX = x - size(Img,2)-1;
                    PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                    PosZoomY = size(Img,1) - y;
                    PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                    % Locate position of points in respect to original img
                    absX = PosZoomX + PosRect(1);
                    absY = PosZoomY + PosRect(2);

                    % Fill every point within delimited perimeter
                    addPolyAreaToDot(absX, absY, SelObjID);
                    delete(animatedLine);
                end
            case {'Refine'}
                if MousePosX > size(Img,2)                    
                    [x,y] = getpoints(animatedLine);
                    if isempty(x) || isempty(y)
                        x = ceil(click_point(1,1));
                        y = ceil(click_point(1,2)); 
                    end                    

                    % Locate position of points in respect to zoom area
                    PosZoomX = x - size(Img,2)-1;
                    PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                    PosZoomY = size(Img,1) - y;
                    PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                    % Locate position of points in respect to original img
                    absX = PosZoomX + PosRect(1);
                    absY = PosZoomY + PosRect(2);
                    
                    % Left-click:  add pixels on path to object
                    % Right-click: remove pixels on path from object                    
                    clickType = get(fig_handle, 'SelectionType');
                    
                    if strcmp(clickType, 'normal')                       
                        ZoomFactor = size(Img,1) / CutNumVox(1);
                        brushSizeScaled = brushSize * ZoomFactor;
                        addPxToDot(absX, absY, brushSizeScaled, SelObjID);                
                    elseif strcmp(clickType, 'alt') 
                        ZoomFactor = size(Img,1) / CutNumVox(1);
                        brushSizeScaled = brushSize * ZoomFactor;                        
                        removePxFromDot(absX, absY, brushSizeScaled, SelObjID);                                                
                    end
                    delete(animatedLine);
                end
        end
        refreshRightPanel;
	end

	function on_click(src, event)  %#ok, unused arguments
        if ~click
            % ** User moved the mouse without clicking anywhere **

            % Set the proper mouse pointer appearance
            set(fig_handle, 'Units', 'pixels');
            click_point = get(gca, 'CurrentPoint');
            PosX = ceil(click_point(1,1));
            PosY = ceil(click_point(1,2));
            ZoomFactor = size(Img,1) / CutNumVox(1);
                        
            if PosY < 0 || PosY > size(Img,1)-(brushSize*0.50*ZoomFactor)
                % Display the default arrow everywhere else
                set(fig_handle, 'Pointer', 'arrow');
                if isvalid(brush), delete(brush); end 
                return;
            end
            
            if PosX <= size(Img,2)
                % Mouse in Left Panel, display a hand
                oldPointer = get(fig_handle, 'Pointer');
                if ~strcmp(oldPointer, 'watch')
                    set(fig_handle, 'Pointer', 'fleur');
                end
                if isvalid(brush), delete(brush); end                    

            elseif PosX <= size(Img,2)*2
                % Mouse in Right Panel, act depending of the selected tool
                switch actionType
                    case {'Enclose', 'Select'}
                        oldPointer = get(fig_handle, 'Pointer');
                        if ~strcmp(oldPointer, 'watch')                        
                            [PCData, PHotSpot] = getPointerCrosshair;
                            set(fig_handle, 'Pointer', 'custom', 'PointerShapeCData', PCData, 'PointerShapeHotSpot', PHotSpot);
                        end
                        if isvalid(brush), delete(brush); end 
                    case {'Add', 'Refine', 'MagicWand'}                        
                        % Display a circle if we are in the right panel
                        set(fig_handle, 'pointer', 'custom', 'PointerShapeCData', NaN(16,16));                    

                        % Recreate the brush because frame is redrawn otherwise
                        % just redraw the brush in the new location
                        ZoomFactor = size(Img,1) / CutNumVox(1);
                        
                        brushSizeScaled = brushSize * ZoomFactor;
                        PosXfenced = max(brushSizeScaled/2, min(PosX-brushSizeScaled/2, size(Img,2)*2-brushSizeScaled-2));
                        PosYfenced = max(brushSizeScaled/2, min(PosY-brushSizeScaled/2, size(Img,1)*2-brushSizeScaled-2)); 
                        brushPos = [PosXfenced, PosYfenced, brushSizeScaled, brushSizeScaled];
                        PosMouse = [PosX, PosY];
%                         disp(['X:' num2str(PosX) ' brushX:' num2str(brushPos(1)) ' Y:' num2str(PosY) ' brushY:' num2str(brushPos(2)) ' brushSize:' num2str(brushSizeScaled)]);

                        if ~isvalid(brush)  
                            brush = rectangle(axes_handle,'Position', brushPos,'Curvature',[1 1],'EdgeColor',[1 1 0],'LineWidth',2,'LineStyle','-');
                        else
                            set(brush, 'Position',  brushPos);
                        end                        
                end
            else
                % Display the default arrow everywhere else
                oldPointer = get(fig_handle, 'Pointer');
                if ~strcmp(oldPointer, 'watch')
                    set(fig_handle, 'Pointer', 'arrow');
                end
                if isvalid(brush), delete(brush); end                    
            end                       
        else
            % ** User clicked on the image get XY-coordinates in pixels **
            
            set(fig_handle, 'Units', 'pixels');
            click_point = get(gca, 'CurrentPoint');
            PosX = ceil(click_point(1,1));
            PosY = ceil(click_point(1,2));
            PosMouse = [PosX, PosY];
            
            if PosX <= size(Img,2)
                % ** User clicked in the Left panel (image navigator) **
                % Mozed the zoomed region to that center point
                % Make sure zoom rectangle is within image area
                ClickPos = [max(CutNumVox(2)/2+1, PosX),...
                            max(CutNumVox(1)/2+1, PosY)];
                    
                ClickPos = [min(size(Img,2)-CutNumVox(2)/2,ClickPos(1)),...
                            min(size(Img,1)-CutNumVox(1)/2,ClickPos(2))];
                Pos      = ClickPos;
                PosZoom  = [-1, -1];
                PosRect  = [ClickPos(1)-CutNumVox(2)/2, ClickPos(2)-CutNumVox(1)/2];
                refreshLeftPanel;
            else
                % ** User clicked in the right panel (zoomed region) **
                % Detect coordinates of the point clicked in PosZoom
                % Note: x,y coordinates are inverted in ImStk
                % Note: x,y coordinates are inverted in CutNumVox                
                PosZoomX = PosX - size(Img,1)-1;
                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));
                
                PosZoomY = size(Img,2) - PosY;
                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                % Do different things depending whether left/right-clicked
                clickType = get(fig_handle, 'SelectionType');                                
                if strcmp(clickType, 'alt')
                    % User RIGHT-clicked in the right panel (zoomed region)
                    switch actionType
                            case {'Add', 'Select', 'Enclose', 'MagicWand'}
                                % Locate position of points in respect to zoom area
                                PosZoomX = PosX - size(Img,2)-1;
                                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                                PosZoomY = size(Img,1) - PosY;
                                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                                % Locate position of points in respect to original img
                                absX = PosZoomX + PosRect(1);
                                absY = PosZoomY + PosRect(2);
                                Pos     = [absX,absY];
                                PosZoom = [-1, -1];
                                refreshBothPanels;
                                
                            case 'Refine'
                                % Remove selected pixels from Dot #ID
                                if isvalid(brush), delete(brush); end
                                
                                PosZoom = [PosZoomX, PosZoomY];
                                Pos     = [Pos(1), Pos(2)];

                                % Absolute position of pixel clicked on right panel
                                % position Pos. Note: Pos(2) is X, Pos(1) is Y
                                fymin = max(ceil(Pos(2) - CutNumVox(1)/2), 1);
                                fymax = min(ceil(Pos(2) + CutNumVox(1)/2), size(Img,1));
                                fxmin = max(ceil(Pos(1) - CutNumVox(2)/2), 1);
                                fxmax = min(ceil(Pos(1) + CutNumVox(2)/2), size(Img,2));
                                fxpad = CutNumVox(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
                                fypad = CutNumVox(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image                    
                                absX  = fxpad+fxmin+PosZoom(1);
                                absY  = fypad+fymin+PosZoom(2);
                                if absX>0 && absX<=size(Img,2) && absY>0 && absY<=size(Img,1)
                                    if ~isvalid(animatedLine)
                                        ZoomFactor = size(Img,1) / CutNumVox(1);
                                        brushSizeScaled = brushSize * ZoomFactor;                                        
                                        animatedLine = animatedline('LineWidth', brushSizeScaled/(2*pi), 'Color', 'red');
                                    else
                                        addpoints(animatedLine, PosX, PosY); 
                                    end                                     
                                end
                    end                   
                elseif strcmp(clickType, 'normal')
                    % User LEFT-clicked in the right panel (zoomed region)
                    PosZoom = [PosZoomX, PosZoomY];
                    Pos     = [Pos(1), Pos(2)];
                                        
                    % Absolute position on image of point clicked on right panel
                    % position Pos. Note: Pos(2) is X, Pos(1) is Y
                    fymin = max(ceil(Pos(2) - CutNumVox(1)/2), 1);
                    fymax = min(ceil(Pos(2) + CutNumVox(1)/2), size(Img,1));
                    fxmin = max(ceil(Pos(1) - CutNumVox(2)/2), 1);
                    fxmax = min(ceil(Pos(1) + CutNumVox(2)/2), size(Img,2));
                    fxpad = CutNumVox(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
                    fypad = CutNumVox(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image                    
                    absX  = fxpad+fxmin+PosZoom(1);
                    absY  = fypad+fymin+PosZoom(2);

                    if absX>0 && absX<=size(Img,2) && absY>0 && absY<=size(Img,1)
                        switch actionType
                            case 'Add'
                                % Create a new Dot in this location
                                ZoomFactor = size(Img,1) / CutNumVox(1);
                                brushSizeScaled = brushSize * ZoomFactor;                                
                                addDot(absX, absY, brushSizeScaled);                                
                            case 'Refine'
                                % Add selected pixels to Dot #ID
                                if isvalid(brush), delete(brush); end
                                if ~isvalid(animatedLine)
                                    ZoomFactor = size(Img,1) / CutNumVox(1);
                                    brushSizeScaled = brushSize * ZoomFactor;                                      
                                    animatedLine = animatedline('LineWidth', brushSizeScaled/(2*pi), 'Color', 'blue');
                                else
                                    addpoints(animatedLine, PosX, PosY); 
                                end 
                            case 'Select'
                                % Locate position of points in respect to zoom area
                                PosZoomX = PosX - size(Img,2)-1;
                                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                                PosZoomY = size(Img,1) - PosY;
                                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));
                                PosZoom = [PosZoomX, PosZoomY];
                                
                                % Select the Dot below mouse pointer
                                set(fig_handle, 'CurrentAxes', axes_handle);
                                SelObjID = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, 0, Prefs, 'right');
                                if SelObjID > 0
                                    set(lstDots, 'Value', SelObjID);
                                end
                            case 'Enclose'
                                % Set mouse pointer shape to a crosshair
                                [PCData, PHotSpot] = getPointerCrosshair;
                                set(fig_handle, 'Pointer', 'custom', 'PointerShapeCData', PCData, 'PointerShapeHotSpot', PHotSpot);
                                if isvalid(brush), delete(brush); end 

                                % Add selected pixels to Dot #ID
                                if ~isvalid(animatedLine)
                                    animatedLine = animatedline('LineWidth', 1, 'Color', 'blue');
                                else
                                    addpoints(animatedLine, PosX, PosY); 
                                end
                            case 'MagicWand'
                                % Create a new Dot using magicwand2
                                ZoomFactor = size(Img,1) / CutNumVox(1);
                                brushSizeScaled = brushSize * ZoomFactor;                                
                                addDotMagicWand(absX, absY, brushSizeScaled);                                
                        end
                    end
                end

            end
        end
    end

	function refreshBothPanels
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','off');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'both');
        if SelObjID > 0
            set(lstDots, 'Value', SelObjID);
        end
    end

	function refreshRightPanel
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','off');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'right');
        if SelObjID > 0
            set(lstDots, 'Value', SelObjID);
        end
    end

	function refreshLeftPanel
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','on');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'left');
    end
end

function [SelectedObjID, image_handle, navi_handle] = redraw(image_handle, navi_handle, ShowObjects, Pos, PosZoom, Post, NaviRectSize, Dots, Filter, SelectedObjID, Settings, WhichPanel)
%% Redraw function, full image on left panel, zoomed area on right panel
% Note: Post(1) and PostCut(1) = Y location,Post(2) PostCut(2) = X location

f               = Post(:,:,1:3);
PostCut         = zeros(NaviRectSize(1), NaviRectSize(2), 3, 'uint8');
PostCutResized  = zeros(size(Post,1), size(Post,2), 3, 'uint8');
PostVoxMapCut   = PostCut;

if (Pos(1) > 0) && (Pos(2) > 0) && (Pos(1) < size(Post,2)) && (Pos(2) < size(Post,1))
    % Identify XY borders of the area to zoom according to passed mouse
    % position Pos. Note: Pos(2) is X, Pos(1) is Y
    fxmin = max(ceil(Pos(2) - NaviRectSize(1)/2)+1, 1);
    fxmax = min(ceil(Pos(2) + NaviRectSize(1)/2), size(Post,1));
    fymin = max(ceil(Pos(1) - NaviRectSize(2)/2)+1, 1);
    fymax = min(ceil(Pos(1) + NaviRectSize(2)/2), size(Post,2));
    fxpad = NaviRectSize(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
    fypad = NaviRectSize(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image
    
    % Find which objects are within the zoomed area
    passIcut = Filter;
    for i = 1:numel(passIcut)
        passIcut(i) = (Dots.Pos(i,2)>fxmin) && (Dots.Pos(i,2)<fxmax) && (Dots.Pos(i,1)>fymin) && (Dots.Pos(i,1)<fymax);
    end
    
    % Flag voxels of passing objects that are within zoomed area
    VisObjIDs = find(passIcut);
    for i = 1:numel(VisObjIDs)
        
        if VisObjIDs(i) == SelectedObjID
            ColorDot =  Settings.ColorSelected;
        else
            switch Filter(VisObjIDs(i))
                case 1,    ColorDot = Settings.ColorValid;
                case 0,    ColorDot = Settings.ColorMaybe;
                case -1,   ColorDot = Settings.ColorFalse;
                otherwise, ColorDot = Settings.ColorValid;
            end
        end
        
        VoxPos = Dots.Vox(VisObjIDs(i)).Pos;
        if strfind(Settings.Type, 'Eyelid')
            VoxPos(:,1) = VoxPos(:,1)+fxpad-fxmin;
            VoxPos(:,2) = VoxPos(:,2)+fypad-fymin;
            for j = 1:size(VoxPos,1)
                PostVoxMapCut(VoxPos(j,1),VoxPos(j,2),:) = ColorDot;
            end
        else    
        for j = 1:size(VoxPos,1)
            if (VoxPos(j,1)>fxmin) && (VoxPos(j,1)<fxmax) && (VoxPos(j,2)>fymin) && (VoxPos(j,2)<fymax)
                %disp('found voxel within selection area');                
                PostVoxMapCut(VoxPos(j,1)+fxpad-fxmin,VoxPos(j,2)+fypad-fymin,:) = ColorDot;
            end
        end
        end
    end
        
    if SelectedObjID == 0 && PosZoom(1)>0 && PosZoom(2)>0
        % If user clicked a location within the zoomed region belonging to an object, select it
        for i=1:numel(VisObjIDs)
            VoxPos = Dots.Vox(VisObjIDs(i)).Pos;
            for j = 1:size(VoxPos,1)
                if ( VoxPos(j,1)==(fxpad+fxmin+PosZoom(2)) ) && (VoxPos(j,2)==(fypad+fymin+PosZoom(1)) )
                    %disp('clicked voxel belongs to a validated object');
                    SelectedObjID = VisObjIDs(i); % Return ID of selected object
                    for k = 1:size(VoxPos,1)
                        % Highlight all voxels belonging to this object
                        PostVoxMapCut(VoxPos(k,1)+fxpad-fxmin+1, VoxPos(k,2)+fypad-fymin+1, :) = Settings.ColorSelected;
                    end
                    break
                end
            end
        end
    end
    
    % Draw the right panel containing a zoomed version of selected area
    PostCut(fxpad+1:fxpad+fxmax-fxmin, fypad+1:fypad+fymax-fymin,:) = f(fxmin:fxmax-1, fymin:fymax-1, :);
    if ShowObjects
        PostCutResized = imresize(PostCut+PostVoxMapCut,[size(Post,1), size(Post,2)], 'nearest');
    else
        PostCutResized = imresize(PostCut,[size(Post,1), size(Post,2)], 'nearest');
    end    
    
    % Separate left and right panel visually with a vertical grey line
    PostCutResized(1:end, 1:4, 1:3) = 75;  
end

if image_handle == 0
    % Draw the full image if it is the first time
    image_handle = image(cat(2, f, PostCutResized));
    axis image off
    % Draw a rectangle border over the selected area (left panel)
    navi_handle = rectangle(gca, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)],'EdgeColor', [1 1 0],'LineWidth',2,'LineStyle','-');
else
    % If we already drawn the image once, just update WhichPanel is needed
    switch  WhichPanel       
        case 'both'
            CData = get(image_handle, 'CData');
            CData(:, size(CData,2)/2+1:size(CData,2),:) = PostCutResized;
            set(image_handle, 'CData', CData);   
            set(navi_handle, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)]);
        case 'left'
            set(navi_handle, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)]);
        case 'right'
            CData = get(image_handle, 'CData');
            CData(:, size(CData,2)/2+1:size(CData,2),:) = PostCutResized;
            set(image_handle, 'CData', CData);   
    end
end
end

function [ShapeCData, HotSpot] = getPointerCrosshair
    %% Custom mouse crosshair pointer sensitive at arms intersection point 
    ShapeCData          = zeros(32,32);
    ShapeCData(:,:)     = NaN;
    ShapeCData(15:17,:) = 1;
    ShapeCData(:, 15:17)= 1;
    ShapeCData(16,:)    = 2;
    ShapeCData(:, 16)   = 2;
    HotSpot             = [16,16];
end