function [selectedMEPs, selectedIdx] = selectingMEP(allMEP, t)

%{
      data should be a matrix of the MEP wished to be analysed with the 
      following format :
               each column is a different MEP (MEP(i,:) - EMG data of ith MEP)
%}

% Create a figure
f = uifigure('Name', 'MEP Selection', 'Position', [100 100 1000 600]);

uilabel(f, ...
    'Text', 'Select the MEPs and click "Export Selected MEPs"', ...
    'Position', [50 565 600 25], ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

uilabel(f, ...
    'Text', 'Please make sure to select only MEP-shaped signals to ensure proper use of the next functions.', ...
    'Position', [50 540 700 20], ...
    'FontSize', 13);

ax = uiaxes('Parent', f, 'Position', [50 130 650 400]);
% position in [%]
hold(ax, 'on');

% Plot all the MEPs
hLines=plot(ax,t',allMEP);
xlabel(ax,'Time (ms)')
ylabel(ax,'Amplitude (V)')
xline(ax,0,'r--','Stimulation');
title(ax, 'MEP Selection');

% Create checkbox panel (empty)
panel = uipanel(f,...
    'Title','MEPs',...
    'Position',[730 50 240 490],...
    'Scrollable','on');

% Add all the checkboxes and their state
nMEP = size(allMEP, 2);

f.UserData.cb = cell(nMEP,1); 
f.UserData.completed = false;
f.UserData.selectedMEPs = [];
f.UserData.selectedIdx = [];
f.UserData.lastSelected = nMEP;
f.UserData.displayMode = "all";

for i = 1:nMEP
    f.UserData.cb{i} = uicheckbox(panel,...
        'Text',sprintf('MEP %d',i),...
        'Value',true,...
        'Position',[15 nMEP*26-25*i 120 20],...
        'ValueChangedFcn',...
        @(src,evt)toggleMEP(src,i,f,hLines));
end

% Buttons

uibutton(f,...
    'Text','Select All',...
    'Position',[50 50 110 40],...
    'ButtonPushedFcn',...
    @(src,evt)selectAll(f,hLines));

uibutton(f,...
    'Text','Deselect All',...
    'Position',[170 50 110 40],...
    'ButtonPushedFcn',...
    @(src,evt)deselectAll(f,hLines));

uilabel(f,...
    'Text','Display Mode:',...
    'Position',[300 60 80 22],...
    'HorizontalAlignment', 'right');

uidropdown(f,...
    'Items',{'Show All Selected','Show Last Selected Only'},...
    'Value','Show All Selected',...
    'Position',[390 60 150 22],...
    'ValueChangedFcn',...
    @(src,evt)changeDisplayMode(src,f,hLines));


uibutton(f, 'Text', 'Export Selected MEPs', ...
    'Position', [560 50 140 40], ...
    'BackgroundColor', [0.8 0.95 0.8], ...
    'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(src,evt)extractingSelectedMEPs(allMEP,f));

% Wait for the user to complete selection

updateDisplay(f,hLines);
uiwait(f)

% Retrieve results
if isvalid(f)
    selectedMEPs = f.UserData.selectedMEPs;
    selectedIdx  = f.UserData.selectedIdx;
    delete(f);
else
    selectedMEPs = [];
    selectedIdx = [];
end

end

%% Function that will display or not MEP

function toggleMEP(src,idx,f,hLines)
if src.Value
    f.UserData.lastSelected = idx;
else
    if f.UserData.lastSelected == idx
        f.UserData.lastSelected = []; 
        for k = length(f.UserData.cb):-1:1
            if f.UserData.cb{k}.Value
                f.UserData.lastSelected = k;
                break;
            end
        end
    end
end
updateDisplay(f,hLines);
end

%% Functions to change the display mode

function changeDisplayMode(src,f,hLines)
if strcmp(src.Value,'Show All Selected')
    f.UserData.displayMode = "all";
else
    f.UserData.displayMode = "last";
end
updateDisplay(f,hLines);
end

function updateDisplay(f,hLines)
cb = f.UserData.cb;
selected = cellfun(@(x) logical(x.Value), cb, 'UniformOutput', true);

switch f.UserData.displayMode
    case "all"
        for k = 1:length(hLines)
            if selected(k)
                hLines(k).Visible = 'on';
            else
                hLines(k).Visible = 'off';
            end
        end

    case "last"
        for k = 1:length(hLines)
            hLines(k).Visible = 'off';
        end
        
        idx = f.UserData.lastSelected;
        if ~isempty(idx) && idx <= length(hLines)
            if selected(idx)
                hLines(idx).Visible = 'on';
            end
        end
end
drawnow
end

%% Functions to select and deselect all MEPs

function selectAll(f,hLines)
for k = 1:length(f.UserData.cb)
    f.UserData.cb{k}.Value = true;
end
f.UserData.lastSelected = length(f.UserData.cb);
updateDisplay(f,hLines);
end

function deselectAll(f,hLines)
for k = 1:length(f.UserData.cb)
    f.UserData.cb{k}.Value = false;
end
f.UserData.lastSelected = [];
updateDisplay(f,hLines);
end

%% Function that returns only the selected MEPs

function extractingSelectedMEPs(allMEP,f)
cb = f.UserData.cb;
selected = cellfun(@(x) logical(x.Value), cb, 'UniformOutput', true);

% if only want the MEP signals:
% % Extract only selected MEPs
% selectedMEPs = MEP(:, selected);   % rows = trials, cols = time points
%
% % Transpose so that each column is one trial
% resultMatrix = selectedMEPs';      % now: (time points × trials)
%
% % Display size in command window
% disp(size(resultMatrix));
% % Export to workspace
% assignin('base', 'SelectedMEPs', resultMatrix);

% Collect all the samples of selected MEPs
f.UserData.selectedIdx = find(selected);
f.UserData.selectedMEPs = allMEP(:,selected);
f.UserData.completed = true;

% Export to workspace
% assignin('base', 'SelectedMEPs', selectedMEPs);
% assignin('base', 'SelectedIdx', selectedIdx);

% Display confirmation in command window
fprintf('Exported %d selected MEPs.\n', sum(selected));
uiresume(f)
end