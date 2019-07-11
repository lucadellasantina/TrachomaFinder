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

function Net = loadNeuralNet(RequestedUID, FieldNames)
%% Load objects matching ObjName
NetFolder = [userpath filesep 'FollicleFinder' filesep 'NeuralNet']; 

if nargin <2
    FieldNames = {};
end

files = dir(NetFolder);         % List the content of /Objects folder
    files = files(~[files.isdir]);  % Keep only files, discard subfolders
    
    for d = 1:numel(files)
        load([NetFolder filesep files(d).name],'UID');
        if strcmp(UID, RequestedUID)
            if isempty(FieldNames)
                Net = load([NetFolder filesep files(d).name]);
            else
                Net = load([NetFolder filesep files(d).name], FieldNames{:});                
            end
            return;
        end
    end
end