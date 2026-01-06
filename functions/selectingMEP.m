function [selectedMEPs, selectedIdx] = selectingMEP(allMEP, t)

    %{
      data should be a matrix of the MEP wished to be analysed with the 
      following format :
               each column is a different MEP (MEP(i,:) - EMG data of ith MEP)
    %}
    
      % Create a figure
    f = uifigure('Name', 'MEP Selection', 'Position', [100 100 1000 600]);

    titleLabel = uilabel(f, ...
        'Text', 'Select the MEPs and click "Export Selected MEPs"', ...
        'Position', [100 560 700 25], ...
        'FontSize', 14, ...
        'FontWeight', 'bold');

    infoLabel = uilabel(f, ...
        'Text', 'Please make sure to select only MEP-shaped signals to ensure proper use of the next functions.', ...
        'Position', [100 535 700 20], ...
        'FontSize', 13);

    ax = uiaxes('Parent', f, 'Position', [100 120 600 400]);
                                        % position in [%]
    hold(ax, 'on');

    % Plot all the MEPs
    hLines = plot(ax, t', allMEP);
    xlabel(ax, 'Time (ms)');
    ylabel(ax, 'Amplitude (V)');
    xline(ax, 0, 'r--', 'Stimulation', 'LabelHorizontalAlignment', 'left')
    title(ax, 'Select MEPs using checkboxes');

    % Create checkbox panel (empty)
    panel = uipanel('Parent', f, 'Title', 'Select MEPs', ...
                    'Position', [750 120 200 400], ...
                    'Scrollable', 'on');

    % Add all the checkboxes and their state
    nMEP = size(allMEP, 2);

    cb = gobjects(nMEP, 1);  % here to display graphics object
    for i = 1:nMEP      % creating a button for each MEP
        cb(i) = uicheckbox(panel, ...
                           'Text', sprintf('MEP %d', i), ...
                           'Value', true, ...   % all selected initially
                           'Position', [10, nMEP*26 - 25*i, 120, 20], ...
                           'ValueChangedFcn', @(src,~) toggleMEP(src, hLines(i)));
    end

    % Initialize variables for waiting
    f.UserData.completed = false;
    f.UserData.selectedMEPs = {};
    f.UserData.selectedIdx  = [];

    % Button for analysis
    uibutton(f, 'Text', 'Export Selected MEPs', ...
             'Position', [400 40 200 40], ...
             'ButtonPushedFcn', @(~,~) extractingSelectedMEPs(allMEP, cb,f));

    % Wait for the user to complete selection
    while isvalid(f) && ~f.UserData.completed
        drawnow;  % Process GUI events
        pause(0.1);  % Small pause to prevent excessive CPU usage
    end

     % Retrieve results
    if isvalid(f)
        selectedMEPs = f.UserData.selectedMEPs;
        selectedIdx  = f.UserData.selectedIdx;
        close(f);
    else
        selectedMEPs = {};
        selectedIdx  = [];
    end

end

%% Function that will display or not MEP
function toggleMEP(src, hLine)
    if src.Value
        hLine.Visible = 'on';
    else
        hLine.Visible = 'off';
    end
end

%% Function that returns only the selected MEPs
function extractingSelectedMEPs(allMEP, cb, f)
   
    selected = logical(arrayfun(@(x) x.Value, cb));

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
    selectedIdx = find(selected);                 % indices of selected MEPs
    selectedMEPs = allMEP(:, selected);           % actual MEP signals
    
    f.UserData.selectedMEPs = selectedMEPs;
    f.UserData.selectedIdx = selectedIdx;
    f.UserData.completed = true;

    % Export to workspace
    % assignin('base', 'SelectedMEPs', selectedMEPs);
    % assignin('base', 'SelectedIdx', selectedIdx);
    
    % Display confirmation in command window
    fprintf('✅ Exported %d selected MEPs to variable "SelectedMEPs" in workspace.\n', sum(selected));
    
end