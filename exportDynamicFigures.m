function exportDynamicFigures()
    figs = findall(0, 'Type', 'figure');
    for i = 1:length(figs)
        fig = figs(i);
        idx = getappdata(fig, 'EulerPlotIndex');
        if isempty(idx)
            continue; % skip non-dynamic figures
        end
        writePlotDataInJSON(idx, fig);
    end
end