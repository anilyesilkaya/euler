function convertBase64PNGToPlotly(inputFile, outputFile)
    % Read original HTML
    html = fileread(inputFile);

    % Insert Plotly.js loader in <head> if not present
    if ~contains(html, 'plotly-latest.min.js')
        headPos = strfind(html, '<head>');
        if ~isempty(headPos)
            insertAt = headPos(1) + length('<head>') - 1;
            html = [html(1:insertAt), ...
                    sprintf('\n<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>\n'), ...
                    html(insertAt+1:end)];
        end
    end

    % Regular expression to match all blocks with base64 images
    % data-testid="output_(\d+)" --  captures the numeric part of the output index
    % style="[^"]*?width:\s*(\d+)px -- captures the numeric pixel width
    pattern = ['<div class="inlineElement eoOutputWrapper[^"]*"[^>]*?' ...
               'data-testid="output_(\d+)"[^>]*?' ...
               'style="[^"]*?width:\s*(\d+)px[^"]*?"[^>]*?>' ...
               '.*?<div class="figureElement eoOutputContent"[^>]*?>\s*' ...
               '<img[^>]+src="data:image/png;base64,[^"]+"[^>]*?>\s*' ...
               '</div>\s*</div>'];

    % Find all matches
    [startIdx, endIdx, ~, matches, ~] = regexp(html, pattern, 'start', 'end', 'match', 'tokens', 'dotall');

    % Initialize new HTML
    newHTML = "";
    scriptBlock = sprintf("<script>\n");
    lastIdx = 1;

    for figIdx = 1:length(matches)
        % Append everything up to this match
        newHTML = newHTML + string(html(lastIdx:startIdx(figIdx)-1));

        % Extract values
        outputIdx = str2double(matches{figIdx}{1}) + 1;
        width = str2double(matches{figIdx}{2});
        height = round(0.6 * width);

        % Replace with Plotly div
        divStr = sprintf('<div id="plotDiv%d" style="width:%dpx;height:%dpx;"></div>\n', ...
                         outputIdx, width, height);
        newHTML = newHTML + divStr;

        % Add script for this div
        scriptBlock = scriptBlock + sprintf([
            'fetch("plot%d.json")\n' ...
            '  .then(response => response.json())\n' ...
            '  .then(data => Plotly.newPlot("plotDiv%d", [data]))\n' ...
            '  .catch(err => console.error("Failed to load plot%d.json:", err));\n\n' ...
        ], outputIdx, outputIdx, outputIdx);

        % Update index
        lastIdx = endIdx(figIdx) + 1;
    end

    % Append remaining HTML after last match
    newHTML = newHTML + string(html(lastIdx:end));

    % Close script tag
    scriptBlock = scriptBlock + sprintf("</script>\n");

    % Inject the script at the end of body (if possible), otherwise append
    if contains(newHTML, '</body>')
        newHTML = replace(newHTML, '</body>', scriptBlock + '</body>');
    else
        newHTML = newHTML + scriptBlock;
    end

    % Write to output file
    fid = fopen(outputFile, 'w');
    fwrite(fid, newHTML);
    fclose(fid);

    fprintf('Processed %d image blocks and wrote to "%s"\n', length(matches), outputFile);
end