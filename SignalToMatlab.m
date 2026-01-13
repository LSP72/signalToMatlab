%% About this script
%{
    This script lets you select and extract MEPs from EMG data recorded
    with the CED1401 system and Signal software.

    It expects a single .mat file as input. Therefore, the original
    Signal .cfs file must first be converted using Fabien's function:
                                       'readCFSfile.m'c
    Note: this function does not work on macOS.

    * * * * *

    If you run into any issue, please contact me.
    — Mathilde
%}

%% Clearing the environment
clc
clear
close all

addpath("functions");
addpath("matcfs64c");

%% Export .cfs to .mat
% IF ON MACOS, IGNORE THIS SECTION AND RUN THE NEXT ONE

% % 1) Select the .cfs file
% [cfFile, cfPath] = uigetfile({'*.cfs','Signal files (*.cfs)'}, ...
%                               'Select the .cfs file');
% if isequal(cfFile,0)
%     error('No .cfs file selected. Operation cancelled.');
% end
% cfFull = fullfile(cfPath, cfFile);
% 
% % 2) Read the .cfs using Fabien's function
% tmp = readCFSfile(cfFull);
% 
% % 3) Choose the name and location for saving the .mat
% [~, baseName] = fileparts(cfFile);
% defaultMatName = [regexprep(baseName, '\s+', '_') '.mat']; % replace spaces with "_"
% [matFile, matPath] = uiputfile({'*.mat','MAT-file (*.mat)'}, ...
%                                'Save as...', defaultMatName);
% if isequal(matFile,0)
%     error('Save cancelled.');
% end
% matFull = fullfile(matPath, matFile);
% 
% % 4) Save
% save(matFull, 'tmp', '-v7.3');
% fprintf('MAT file saved: %s\n', matFull);

%% Looking for the file & loading the data
% IF ON WINDOWS, YOU CAN DIRECTLY RUN THE ABOVE SECTION BUT RUN THAT ONE
% TOO

[file, file_dir] = uigetfile('*.mat');
str_file = convertCharsToStrings(file);
str_file_dir = convertCharsToStrings(file_dir);
str_file_path = str_file_dir + str_file;
tmp = load(str_file_path);
fprintf('OK — MAT loaded (%s). Fields reindexed.\n', str_file);
                                % POURQUOI ??
%% Cleaning the field names

fields_tmp = fieldnames(tmp);
raw_indexed_data = tmp.(fields_tmp{1});
raw_fields = fieldnames(raw_indexed_data);
EMG_field = "EMG_"+num2str(5);
% Reindexing the structure to use labels easier
data = struct();
for i =1:3
    data.(raw_fields{i}) = raw_indexed_data.(raw_fields{i});
end
nb_EMGs = 1;
for i = 4:numel(raw_fields)-nb_EMGs
    oldName = raw_fields{i};
    newName = oldName(1:end-2);   % removes the last 2 chars ('_X')
    data.(newName) = raw_indexed_data.(oldName);
end
for i = numel(raw_fields)-nb_EMGs+1:numel(raw_fields)
    data.(raw_fields{i}) = raw_indexed_data.(raw_fields{i});
end

%% Get signals : EMG / Stim

% Get the EMG signal and filter it
% TODO: there may be multiple EMG channels
%       => decide how to select the appropriate channel

if any(strcmp(raw_fields, EMG_field))
    EMG = data.(EMG_field).dat;
    freq_EMG = data.(EMG_field).FreqS;
end

% Using Silvère's filtering function
EMG_filtered = filtrage(EMG, freq_EMG, 20, 1000);

% Get the stimulation signal considering
% the signal was acquired on the ADC0
stim = data.ADC0.dat;
freq_stim = data.ADC0.FreqS;

fprintf('OK — EMG filtered (20–1000 Hz, Fs=%.1f Hz). Stim loaded (Fs=%.1f Hz).\n', freq_EMG, freq_stim);

%% Match sampling rates (resample stim to EMG rate)
% Target sampling frequency = EMG sampling rate = freq_EMG

% end_time_EMG = length(EMG) * (1/freq_EMG);
% time_EMG = linspace(0, end_time_EMG, length(EMG));
% new_time_EMG = 0:(1/freq_EMG):end_time_EMG-1;

end_time_stim = length(stim)*(1/freq_stim);
time_stim = linspace(0, end_time_stim, length(stim));   % actual time vector of the recorder stim
new_time_stim = (0:length(EMG)-1) / freq_EMG;           % new time vector of the stim matchnig the frequency of the EMG

% Interpolation stim onto the EMG time base
new_stim = interp1(time_stim, stim, new_time_stim, 'linear');

%% Detect stimulation times

Thr = 0.3; % threshold: stim signal above 0.3 V
                                                                            % Indices of detected stim events
listOfStim=(new_stim>Thr);                                                  % Values above threshold
listOfStim=find(diff(listOfStim)==1)+1;                                     % Rising edges

fprintf('OK — Stim detection completed.\n')

%% Build MEP windows
% Define the window where the MEP should appear (stim -100 ms, stim +500 ms)

MEPWindows = [];
for t = 1:length(listOfStim)
    minus = round(listOfStim(t) - 0.1 * freq_EMG) ; % time of stim - 100ms
    plus = round(listOfStim(t) + 0.5 * freq_EMG) ;  % time of stim + 500ms
    if minus < 1    % ensure the lower bound is within data
        minus = 1;
    end
    if plus > length(EMG_filtered)  % ensure the upper bound is within data
        plus = length(EMG_filtered);
    end

    wdw = [minus, plus];            % time indexes of the window around the stim
    MEPWindows = [MEPWindows; wdw]; % collect windows
end
fprintf('OK — MEP windows created.\n')

%% Extract all MEP segments
% Longueur cible (en nombre d'échantillons)
winLen = MEPWindows(1,2) - MEPWindows(1,1) + 1;  % ou max(...) si ça varie

nWin   = size(MEPWindows,1);
allMEP = nan(winLen, nWin);   % pré-allocation avec NaN

for w = 1:nWin
    fstart = MEPWindows(w,1);
    fend   = MEPWindows(w,2);

    EMG_window = EMG_filtered(fstart:fend);
    L = numel(EMG_window);

    % Adding NaN values if window is smaller than the other
    allMEP(1:L, w) = EMG_window;
end

% Create a time vector for plotting (in ms, aligned with the window definition)
time =  linspace(-100, 500, size(allMEP,1));

% Select valid MEPs (manual/GUI function)
[selectedMEPs, selectedIdx] = selectingMEP(allMEP, time);

%% MEPs structure
% Create MEP struct (keep valid MEPs and rename to MEP_01, MEP_02, ... original naming is reported too)
% and MEP_SELECTION struct (report which MEPs were rejected, which were kept,
% and the total number initially detected)

[MEP, MEP_SELECTION] = renumberLogMEP(selectedMEPs, selectedIdx, allMEP);

% Time centering aroung 0 ms = stim index in MEP window
stimIdx0 = round(0.1 * freq_EMG); % sample for 100 ms (0-based)

% Store at global level (only valid) 
MEP.Meta.Time_ms = time(:).';
MEP.Meta.StimIdx = stimIdx0 + 1;
MEP.Meta.Fs      = freq_EMG;

% Create a struct with all individual MEPs using original naming
originalNamedMEPs = namingMEP(selectedMEPs, selectedIdx);   % creates a struct,
                                                    % if needed later
fprintf('OK — MEP struct created and renumbered (MEP_01..MEP_%02d). Selection log stored.\n', size(selectedMEPs,2));



%% Analyse of the MEPS

% Detect valid MEP windows + peak-to-peak + latency (automatic)

[MEP, T] = detectMEPOnsetOffset(MEP, 'Fs', freq_EMG);
fprintf('OK — Onset/offset, peak-to-peak (p2p), latency, and AUC extracted automatically.\n');

%% === CSV export for statistical analysis: 1 row per MEP; columns = P2P, Latency, AUC ===

% 1) Build the table to export (keep also the MEP label)
% Convert T.Signal to a string to export it to csv after:
T.SignalString = cellfun(@(x) sprintf('%g,', x), T.Signal, 'UniformOutput', false);
T.SignalString = cellfun(@(s) s(1:end-1), T.SignalString, 'UniformOutput', false);

ExportTab = table( ...
    T.Label, ...
    T.P2P_uV, ...
    T.Latency_ms, ...
    T.AUC_uVms, ...
    T.SPduration_ms, ...
    T.SignalString, ...
    'VariableNames', {'MEP_Label','P2P_uV','Latency_ms','AUC_uVms','SP_ms','Raw_signal'});

% 2) Propose a default file name (same folder as the .mat)
[~, baseMatName] = fileparts(char(str_file));  % get .mat file name without extension
defaultCSV = fullfile(char(str_file_dir), sprintf('%s_MEP_metrics.csv', baseMatName));

% 3) Save location
[csvFile, csvPath] = uiputfile({'*.csv','CSV file (*.csv)'}, 'Save MEP metrics as...', defaultCSV);
if isequal(csvFile,0)
    warning('CSV export canceled by user.');
else
    outCSV = fullfile(csvPath, csvFile);
    writetable(ExportTab, outCSV);
    fprintf('CSV exported: %s (N=%d MEPs)\n', outCSV, height(ExportTab));
end