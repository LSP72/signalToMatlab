function [MEPnew] = OnsetOffset_Inspection(MEP)

nb_mep=sum(startsWith(fieldnames(MEP),'MEP'));
fig = uifigure('Name','Onset-Offset Inspection','Position',[100 100 900 600]);
currentIndex = 1;

axesArray = gobjects(nb_mep,1);
plotsArray = gobjects(nb_mep,1);
slider1 = gobjects(nb_mep,1);
slider2 = gobjects(nb_mep,1);
xline1 = gobjects(nb_mep,1);
xline2 = gobjects(nb_mep,1);
sliderLabel1 = gobjects(nb_mep,1);
sliderLabel2 = gobjects(nb_mep,1);
decal = 40;                                                                 % Used to align sliders with the axes

axesPos = [20 150 680 400];

    for k = 1:nb_mep
        ax = uiaxes(fig,'Position',axesPos,'Visible','off');
        axesArray(k) = ax;

        x = MEP.Meta.Time_ms;
        y = MEP.(['MEP_' num2str(k,'%02d')]).Enveloppe;
        plotsArray(k) = plot(ax,x,y,'Visible','off');
        ax.XLim = [min(x) max(x)];

        xlabel(ax,'Time (ms)');
        ylabel(ax,'RMS Enveloppe (V)');
        title(ax,sprintf('MEP %d',k));

        % xlines - onset & offset
        xline1(k) = xline(ax, MEP.Meta.OnOff_ms(k,1), 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'Visible', 'off');
        xline2(k) = xline(ax, MEP.Meta.OnOff_ms(k,2), 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--', 'Visible', 'off');

        % Slider 1 (Onset)
        slider1(k) = uislider(fig, ...
            'Position',[axesPos(1)+decal 100 axesPos(3)-decal 3], ...
            'Limits',[min(x) max(x)], ...
            'Value',MEP.Meta.OnOff_ms(k,1), ...
            'Visible','off');
        slider1(k).ValueChangingFcn = @(s,e) updateXline1(k,e.Value);

        % Slider 2 (Offset)
        slider2(k) = uislider(fig, ...
            'Position',[axesPos(1)+decal 60 axesPos(3)-decal 3], ...
            'Limits',[min(x) max(x)], ...
            'Value',MEP.Meta.OnOff_ms(k,2), ...
            'Visible','off');
        slider2(k).ValueChangingFcn = @(s,e) updateXline2(k,e.Value);

        sliderLabel1(k) = uilabel(fig,'Text','Onset','Position',[axesPos(1)+decal 110 50 20],'FontWeight','bold','Visible','off');
        sliderLabel2(k) = uilabel(fig,'Text','Offset','Position',[axesPos(1)+decal 35 50 20],'FontWeight','bold','Visible','off');
        slider2(k).MajorTicks = [];
        slider2(k).MinorTicks = [];

    end

    % Initial display
    showCurve(1);

    % Buttons to switch curves
    btnX = axesPos(1)+axesPos(3)+30;
    uibutton(fig,'Text','⏮️ First','Position',[btnX 350 120 40],'ButtonPushedFcn',@(btn,event) jumpTo(1));
    uibutton(fig,'Text','⬅️ Previous','Position',[btnX 280 120 40],'ButtonPushedFcn',@(btn,event) switchCurve(-1));
    uibutton(fig,'Text','Next ➡️','Position',[btnX 210 120 40],'ButtonPushedFcn',@(btn,event) switchCurve(1));
    uibutton(fig,'Text','Last ⏭️','Position',[btnX 140 120 40],'ButtonPushedFcn',@(btn,event) jumpTo(nb_mep));
    uibutton(fig,'Text','Finish','Position',[btnX 70 120 40], ...
    'FontColor','r','BackgroundColor',fig.Color,'ButtonPushedFcn',@(btn,event) finishCallback());

    lblInfo = uilabel(fig,'Text',sprintf('MEP %d / %d',currentIndex,nb_mep), ...
    'Position',[btnX 400 120 30],'FontSize',14,'FontWeight','bold');

%%  Functions
%%
    function updateXline1(idx, val)
        xline1(idx).Value = val;
    end

    function updateXline2(idx, val)
        xline2(idx).Value = val;
    end

    function hideCurve(idx)
        axesArray(idx).Visible = 'off';
        plotsArray(idx).Visible = 'off';
        slider1(idx).Visible = 'off';
        slider2(idx).Visible = 'off';
        xline1(idx).Visible = 'off';
        xline2(idx).Visible = 'off';
        sliderLabel1(idx).Visible = 'off';
        sliderLabel2(idx).Visible = 'off';
    end

    function showCurve(idx)
        axesArray(idx).Visible = 'on';
        plotsArray(idx).Visible = 'on';
        slider1(idx).Visible = 'on';
        slider2(idx).Visible = 'on';
        xline1(idx).Visible = 'on';
        xline2(idx).Visible = 'on';
        sliderLabel1(idx).Visible = 'on';
        sliderLabel2(idx).Visible = 'on';

        slider1(idx).Value = xline1(idx).Value;
        slider2(idx).Value = xline2(idx).Value;
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
        positions = zeros(n,2);
        MEPnew=MEP;
        for i = 1:nb_mep
            positions(i,1) = xline1(i).Value;
            positions(i,2) = xline2(i).Value;
            MEPnew.(['MEP_' num2str(i,'%02d')]).OnOff_ms=positions(i,:);
        end
        MEPnew.Meta.OnOff_ms=positions;
        uiresume(fig);
        delete(fig);
    end

    uiwait(fig);

end