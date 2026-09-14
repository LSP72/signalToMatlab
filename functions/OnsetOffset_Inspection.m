function [MEPnew] = OnsetOffset_Inspection(MEP)

mepFields = fieldnames(MEP);
mepNames = mepFields(startsWith(mepFields,'MEP'));
nb_mep = numel(mepNames);

fig = uifigure('Name','Onset-Offset Inspection','Position',[100 100 900 600]);
currentIndex = 1;

axesArray = gobjects(nb_mep,1);
plotsArray = gobjects(nb_mep,1);
slider1 = gobjects(nb_mep,1);
slider2 = gobjects(nb_mep,1);
slider3 = gobjects(nb_mep,1);
xline0 = gobjects(nb_mep,1);
xline1 = gobjects(nb_mep,1);
xline2 = gobjects(nb_mep,1);
xline3 = gobjects(nb_mep,1);
yline1 = gobjects(nb_mep,1);
yline2 = gobjects(nb_mep,1);
sliderLabel1 = gobjects(nb_mep,1);
sliderLabel2 = gobjects(nb_mep,1);
sliderLabel3 = gobjects(nb_mep,1);
checkboxIncluded = gobjects(nb_mep,1);
decal = 40;                                                                 % Used to align sliders with the axes
modifmax=50;                                                                % Maximum manual offset
fitYWindow = false;                                                         % Whether the Y axis is fit to the -100/100ms window only
yFitRange = [-100 100];

axesPos = [20 160 680 400];
btnX = axesPos(1)+axesPos(3)+30;

    for k = 1:nb_mep
        ax = uiaxes(fig,'Position',axesPos,'Visible','off');
        ax.Box = 'on';
        axesArray(k) = ax;
        modifmax_on = modifmax;
        modifmax_off = modifmax;

        x = MEP.Meta.Time_ms;
        y = MEP.(mepNames{k}).Enveloppe;
        plotsArray(k) = plot(ax,x,y,'Visible','off','Color','k','LineWidth',1);
        ax.XLim = [min(x) 400];

        xlabel(ax,'Time (ms)');
        ylabel(ax,'RMS Enveloppe (V)');
        title(ax,mepNames{k},'Interpreter','none');
        onset=MEP.Meta.OnOff_ms(k,1);
        offset=MEP.Meta.OnOff_ms(k,2);
        sp=offset+MEP.(mepNames{k}).Silentperiod;
        onset(isnan(onset)) = 0;
        offset(isnan(offset)) = 0;
        sp(isnan(sp)) = 0;
        sp(sp>400) = 400;

        if onset == 0
            modifmax_on = 100;
        end
        if offset == 0
            modifmax_off = 150;
        end

        % xlines - stim, onset, offset & silent period
        xline0(k) = xline(ax, 0, 'Color', 'r', 'LineWidth', 1.5, 'LineStyle', ':', 'Visible', 'off');
        xline1(k) = xline(ax, onset, 'Color', '#6B43E5', 'LineWidth', 1.7, 'LineStyle', '--', 'Visible', 'off');
        xline2(k) = xline(ax, offset, 'Color', '#E54379', 'LineWidth', 1.7, 'LineStyle', '--', 'Visible', 'off');
        xline3(k) = xline(ax, sp, 'Color', '#AA50DE', 'LineWidth', 1.7, 'LineStyle', '--', 'Visible', 'off');

        % ylines - onset & offset thresholds
        yline1(k) = yline(ax, MEP.(mepNames{k}).Thresholds.on, 'Color', '#6B43E5', 'LineWidth', .7, 'LineStyle', '--', 'Visible', 'off');
        yline2(k) = yline(ax, MEP.(mepNames{k}).Thresholds.off, 'Color', '#E54379', 'LineWidth', .7, 'LineStyle', '--', 'Visible', 'off');

        % Slider 1 (Onset)
        slider1(k) = uislider(fig, ...
            'Position',[axesPos(1)+decal 120 axesPos(3)-decal 3], ...
            'Limits',[0 onset+modifmax_on], ...
            'Value',onset, ...
            'Visible','off');
        slider1(k).ValueChangingFcn = @(s,e) updateXline1(k,e.Value);

        % Slider 2 (Offset)
        slider2(k) = uislider(fig, ...
            'Position',[axesPos(1)+decal 80 axesPos(3)-decal 3], ...
            'Limits',[0 offset+modifmax_off], ...
            'Value',offset, ...
            'Visible','off');
        slider2(k).ValueChangingFcn = @(s,e) updateXline2(k,e.Value);

        % Slider 3 (Silent Period)
        slider3(k) = uislider(fig, ...
            'Position',[axesPos(1)+decal 40 axesPos(3)-decal 3], ...
            'Limits',[0 400], ...
            'Value',sp, ...
            'Visible','off');
        slider3(k).ValueChangingFcn = @(s,e) updateXline3(k,e.Value);

        sliderLabel1(k) = uilabel(fig,'Text','Onset','Position',[axesPos(1)-10 112 50 20],'FontWeight','bold','Visible','off','FontColor','#6B43E5');
        sliderLabel2(k) = uilabel(fig,'Text','Offset','Position',[axesPos(1)-10 72 50 20],'FontWeight','bold','Visible','off','FontColor','#E54379');
        sliderLabel3(k) = uilabel(fig,'Text','Sil.Per.','Position',[axesPos(1)-10 32 50 20],'FontWeight','bold','Visible','off','FontColor','#AA50DE');

        % Checkbox - include/exclude this MEP from the exported structure
        checkboxIncluded(k) = uicheckbox(fig, ...
            'Text','Included if checked', ...
            'Position',[btnX 405 150 22], ...
            'Value',true, ...
            'FontWeight','bold', ...
            'Visible','off');

    end

    % Checkbox - fit the Y axis to the MEP window only
    fitYCheckbox = uicheckbox(fig, ...
        'Text','Fit Y axis on MEP window (-100 to 100 ms)', ...
        'Position',[axesPos(1) axesPos(2)+axesPos(4)+5 400 22], ...
        'Value',false, ...
        'ValueChangedFcn',@(src,evt) toggleFitY(src.Value));

    % Initial display
    showCurve(1);

    % Buttons to switch curves
    uibutton(fig,'Text','⏮️ First','Position',[btnX 350 120 40],'ButtonPushedFcn',@(btn,event) jumpTo(1));
    uibutton(fig,'Text','⬅️ Previous','Position',[btnX 280 120 40],'ButtonPushedFcn',@(btn,event) switchCurve(-1));
    uibutton(fig,'Text','Next ➡️','Position',[btnX 210 120 40],'ButtonPushedFcn',@(btn,event) switchCurve(1));
    uibutton(fig,'Text','Last ⏭️','Position',[btnX 140 120 40],'ButtonPushedFcn',@(btn,event) jumpTo(nb_mep));
    uibutton(fig,'Text','Finish','Position',[btnX 70 120 40], ...
    'FontColor','r','BackgroundColor',fig.Color,'ButtonPushedFcn',@(btn,event) finishCallback());

    lblInfo = uilabel(fig,'Text',sprintf('MEP %d / %d',currentIndex,nb_mep), ...
    'Position',[btnX 440 130 30],'FontSize',14,'FontWeight','bold');

%%  Functions
%%
    function updateXline1(idx, val)
        xline1(idx).Value = val;
    end

    function updateXline2(idx, val)
        xline2(idx).Value = val;
    end

    function updateXline3(idx, val)
        xline3(idx).Value = val;
    end

    function hideCurve(idx)
        axesArray(idx).Visible = 'off';
        plotsArray(idx).Visible = 'off';
        slider1(idx).Visible = 'off';
        slider2(idx).Visible = 'off';
        slider3(idx).Visible = 'off';
        xline0(idx).Visible = 'off';
        xline1(idx).Visible = 'off';
        xline2(idx).Visible = 'off';
        xline3(idx).Visible = 'off';
        yline1(idx).Visible = 'off';
        yline2(idx).Visible = 'off';
        sliderLabel1(idx).Visible = 'off';
        sliderLabel2(idx).Visible = 'off';
        sliderLabel3(idx).Visible = 'off';
        checkboxIncluded(idx).Visible = 'off';
    end

    function showCurve(idx)
        axesArray(idx).Visible = 'on';
        plotsArray(idx).Visible = 'on';
        slider1(idx).Visible = 'on';
        slider2(idx).Visible = 'on';
        slider3(idx).Visible = 'on';
        xline0(idx).Visible = 'on';
        xline1(idx).Visible = 'on';
        xline2(idx).Visible = 'on';
        xline3(idx).Visible = 'on';
        yline1(idx).Visible = 'on';
        yline2(idx).Visible = 'on';
        sliderLabel1(idx).Visible = 'on';
        sliderLabel2(idx).Visible = 'on';
        sliderLabel3(idx).Visible = 'on';
        checkboxIncluded(idx).Visible = 'on';

        slider1(idx).Value = xline1(idx).Value;
        slider2(idx).Value = xline2(idx).Value;
        slider3(idx).Value = xline3(idx).Value;

        applyYFit(idx);
    end

    function toggleFitY(value)
        fitYWindow = logical(value);
        applyYFit(currentIndex);
    end

    function applyYFit(idx)
        ax = axesArray(idx);
        if ~fitYWindow
            ax.YLimMode = 'auto';
            return
        end

        xdata = plotsArray(idx).XData;
        ydata = plotsArray(idx).YData;
        winMask = xdata >= yFitRange(1) & xdata <= yFitRange(2);
        windowData = ydata(winMask);

        if isempty(windowData)
            ax.YLimMode = 'auto';
            return
        end

        yMin = min(windowData);
        yMax = max(windowData);
        if yMax == yMin
            pad = max(abs(yMin), 1) * 0.1;
        else
            pad = (yMax - yMin) * 0.05;
        end
        ax.YLim = [yMin - pad, yMax + pad];
    end

    function switchCurve(dir)
        hideCurve(currentIndex);
        currentIndex = currentIndex + dir;
        if currentIndex > nb_mep, currentIndex = 1; end
        if currentIndex < 1, currentIndex = nb_mep; end
        showCurve(currentIndex);
        lblInfo.Text = sprintf('MEP %d / %d',currentIndex,nb_mep);
    end

    function jumpTo(idx)
        hideCurve(currentIndex);
        currentIndex = idx;
        showCurve(currentIndex);
        lblInfo.Text = sprintf('MEP %d / %d',currentIndex,nb_mep);
    end

    function finishCallback()
        positions = zeros(nb_mep,2);
        positions_idx = zeros(nb_mep,2);
        MEPnew=MEP;
        for i = 1:nb_mep
            positions(i,1) = xline1(i).Value;
            positions(i,2) = xline2(i).Value;
            positions_idx(i,1) = find(abs(x - xline1(i).Value) == min(abs(x - xline1(i).Value)), 1);
            positions_idx(i,2) = find(abs(x - xline2(i).Value) == min(abs(x - xline2(i).Value)), 1);
            MEPnew.(mepNames{i}).OnOff_ms=positions(i,:);
            MEPnew.(mepNames{i}).OnOff_idx=positions_idx(i,:);
            MEPnew.(mepNames{i}).Silentperiod=xline3(i).Value-xline2(i).Value;
            MEPnew.(mepNames{i}).Included=logical(checkboxIncluded(i).Value);
        end
        MEPnew.Meta.OnOff_ms=positions;
        uiresume(fig);
        delete(fig);
    end

    uiwait(fig);

end