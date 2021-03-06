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

function tblN = listNeuralNet
%% List available object names and UIDs
NetFolder = [userpath filesep 'FollicleFinder' filesep 'NeuralNet'];
files = dir([NetFolder filesep '*.mat']); % List the content of /Training folder

tblN = repmat(table({'Empty'}, {'Empty'}, {'Empty'}, {'Empty'}, {datetime}, false, {'Empty'}),numel(files),1);
for d = 1:numel(files)
    N = load([NetFolder filesep files(d).name], 'Name', 'Target', 'Type', 'Model', 'Date', 'Trained', 'UID');
    tblN(d,:) = table({N.Name}, {N.Target}, {N.Type}, {N.Model}, {N.Date}, N.Trained, {N.UID});
end

tblN = sortrows(tblN,1); % Sort table by neural net name
end