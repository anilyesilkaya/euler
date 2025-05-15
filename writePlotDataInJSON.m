function writePlotDataInJSON(idx, h, options)
    arguments
        idx
        h
        options.ColorScale = "Viridis"
    end

    % Process the figure handle
    % Obtain all axes from the figure
    axesHandles = findall(h, 'Type', 'axes');
    axesChildren = axesHandles.Children;
    switch class(axesChildren)
        case 'matlab.graphics.chart.primitive.Surface'
            % Extract data from the surface plot
            xData = axesChildren.XData;
            yData = axesChildren.YData;
            zData = axesChildren.ZData;

            % Prepare data for JSON
            plotData.x = unique(xData, "stable");
            plotData.y = unique(yData, "stable");
            plotData.z = zData;
            plotData.type = "surface";
            plotData.colorscale = options.ColorScale;

            assert(size(plotData.x,2) == 1,"Size of the x data is larger than 1")
            assert(size(plotData.y,2) == 1,"Size of the y data is larger than 1")
        case 'matlab.graphics.chart.primitive.Line'
            % Extract data from the line plot
            xData = axesChildren.XData;
            yData = axesChildren.YData;

            % Prepare data for JSON
            plotData.x = xData;
            plotData.y = yData;
            plotData.type = "line";
            plotData.colorscale = options.ColorScale;

            assert(size(plotData.x,1) == 1,"Size of the x data is larger than 1")
            assert(size(plotData.y,1) == 1,"Size of the y data is larger than 1")
        otherwise
            error("Unknown chart type.")
    end
     % Convert plot data to JSON format
    jsonData = jsonencode(plotData);
    
    % Write JSON data to a file
    fileName = sprintf('plot%d.json', idx);
    fid = fopen(fileName, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', fileName);
    end
    fwrite(fid, jsonData, 'char');
    fclose(fid);
end