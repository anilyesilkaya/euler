function f = figureDynamic()
    % Create the figure
    f = figure;

    % Determine next plot index
    persistent figCount;
    if isempty(figCount)
        figCount = 1;
    else
        figCount = figCount + 1;
    end

    % Store index for later export
    setappdata(f, 'EulerPlotIndex', figCount);
end