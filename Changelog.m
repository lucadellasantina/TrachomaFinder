%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%
%% ChangeLog
%
% Version 1.3 - created on 2019-06-08
%
% + Licensed under the GNU General Public License v3 (GPLv3)
% + Automatic follicle finder using findObjects2D iterative thresholding
%
% Version 1.2 - created on 2019-06-08
%
% + Custom crosshair pointer for pixel-level precision selection
% + Zoomed region drawn in left panel as an overlayed rectangle object
% + Follicle types drawn in different colors (True=g, False=g, Maybe=y)
% + Follicles of all types are drawn on screen
% + Speeded up inspectPhoto by refreshing only the changed panel
% + Fixed inverted direction panning when user right-clicked on right panel
% + Custom circular brush with pixel-level precision for "Add" tool
% + Speeded up "Refine" tool by convolving pixels only at mouseUp event
% + Everytime a new objct is added, it is also selected from list for stats
% + Refine tool uses custom circle mouse pointer same diameter as brush
% + Brush size now correctly scaled when zoom level is changed
% + Allow user to use custom colors to label follicles
% + Store/load preferences across sessions, or restore defaults via button
% + Error in Refine mode when animatedLine had no new pixels to add/remove
% + If user selected listbox item out of field of view, center view on it

% Version 1.1 - created on 2019-06-05
%
% + Diagnosis field to determine the diagnosis for the current photo
% + Filter has 3 modes: 1 = True follicle, -1 = False follicle, 0 = Maybe
% + Enclose mode will automatically add an object if none are selected
%

% Version 1.0 - created on 2019-05-29
%
% + Speeded up painting operation by using overlayed brush
% + Edit modes: Add, Refine, Select, Enclose allow interaction with objects
% 