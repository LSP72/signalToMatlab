function [MEP, MEP_SELECTION] = renumberLogMEP(selectedMEPs, selectedIdx, allMEP)
% RENUNBERLOGMEP Renumbers kept MEPs and logs removed ones, with nested fields.
%
% OUTPUT SHAPE EXAMPLE:
%   MEP.MEP_01.EMG         -> column vector (EMG segment)
%   MEP.MEP_01.orig_idx    -> original index in allMEP (before selection)
%
% INPUTS:
%   selectedMEPs : [Npts x Nkeep] matrix of kept MEPs (columns = MEPs)
%   selectedIdx  : kept-idx returned by selectingMEP (logical or numeric)
%   allMEP       : [Npts x Ntotal] matrix of all detected MEPs (columns = MEPs)
%
% OUTPUTS:
%   MEP : nested struct with fields "MEP_01", "MEP_02", ...
%         Each sub-struct contains:
%           - EMG        : the EMG segment
%           - orig_idx   : original index in allMEP
%   MEP_SELECTION : struct with
%           .n_total
%           .kept_idx
%           .removed_idx

    arguments
        selectedMEPs {mustBeNonempty, mustBeNumeric}
        selectedIdx
        allMEP {mustBeNonempty, mustBeNumeric}
    end

    % --- Normalize kept_idx from selectedIdx (logical or numeric)
    if islogical(selectedIdx)
        kept_idx = find(selectedIdx);
    else
        kept_idx = selectedIdx(:)'; % row vector
        if ~isnumeric(kept_idx) || any(~isfinite(kept_idx)) || any(kept_idx <= 0)
            error('selectedIdx must be logical or a vector of positive numeric indices.');
        end
    end

    % --- Derive totals and removed indices
    n_total = size(allMEP, 2);
    removed_idx = setdiff(1:n_total, kept_idx);

    % --- Build nested struct:
    %     MEP.MEP_XX.EMG = selectedMEPs(:,k);
    %     MEP.MEP_XX.orig_idx   = kept_idx(k);
    MEP = struct();
    n_keep = size(selectedMEPs, 2);
    for k = 1:n_keep
        outerField = sprintf('MEP_%02d', k);
        innerField = sprintf('EMG');

        % Create sub-struct and assign EMG segment + original index
        MEP.(outerField).(innerField) = selectedMEPs(:, k);
        MEP.(outerField).orig_idx     = kept_idx(k);
    end

    % All MEPs from "selectedMEPs" matrix
    MEP.All = selectedMEPs.';

    % --- Summary struct
    MEP_SELECTION = struct( ...
        'n_total',     n_total, ...
        'kept_idx',    kept_idx, ...
        'removed_idx', removed_idx);
end