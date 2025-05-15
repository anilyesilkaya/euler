function convertBase64PNGToPlotly(inputFile, outputFile)
    % Read the original HTML
    html = fileread(inputFile);

    % Ensure Plotly.js is included
    if ~contains(html, 'plotly-latest.min.js')
        headPos = strfind(html, '<head>');
        if ~isempty(headPos)
            idx = headPos(1) + length('<head>') - 1;
            html = [ ...
                html(1:idx), newline, ...
                '<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>', newline, ...
                html(idx+1:end) ...
            ];
        end
    end

    % Regex to find each base64 PNG block and capture (1) output index, (2) width
    pattern = [ ...
      '<div class="inlineElement eoOutputWrapper[^"]*"[^>]*?' ...
      'data-testid="output_(\d+)"[^>]*?' ...
      'style="[^"]*?width:\s*(\d+)px[^"]*?"[^>]*?>' ...
      '.*?<div class="figureElement eoOutputContent"[^>]*?>\s*' ...
      '<img[^>]+src="data:image/png;base64,[^"]+"[^>]*?>\s*' ...
      '</div>\s*</div>' ...
    ];

    % Find all matches
    [startIdx, endIdx, ~, tokens] = regexp(html, pattern, ...
                                           'start','end','match','tokens','dotall');  % :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}

    newHTML     = "";
    scriptBlock = "<script>" + newline;
    lastPos     = 1;

    for k = 1:numel(tokens)
        % 1) Append everything up to this figure block
        newHTML = newHTML + string(html(lastPos:startIdx(k)-1));

        % 2) Extract the captured index and width
        figNum = str2double(tokens{k}{1}) + 1;
        width  = str2double(tokens{k}{2});
        height = round(0.6 * width);

        % 3) Insert a responsive div (100% width, fixed height)
        newHTML = newHTML + sprintf(...
            '<div id="plotDiv%d" style="width:100%%;height:%dpx;"></div>', ...
            figNum, height) + newline;

        % 4) Build the loader with real newlines and a bottom margin
        scriptBlock = scriptBlock + sprintf([ ...
            'fetch("plot%d.json")', newline ...
            '  .then(r => r.json())', newline ...
            '  .then(data => {', newline ...
            '    const gd = document.getElementById("plotDiv%d");', newline ...
            '    Plotly.newPlot(gd, [data], {', newline ...
            '      autosize: true,', newline ...
            '      margin: {t: 30, b: 30, l: 10, r: 10}', newline ...
            '    }, {responsive: true});', newline ...
            '  })', newline ...
            '  .catch(e => console.error("Failed to load plot%d.json:", e));', newline ... 
        ], figNum, figNum, figNum) + newline;

        lastPos = endIdx(k) + 1;
    end

    % 5) Append the tail of the HTML and close the <script>
    newHTML     = newHTML + string(html(lastPos:end));
    scriptBlock = scriptBlock + "</script>" + newline;

    % 6) Inject the loader script just before </body>
    if contains(newHTML, '</body>')
        newHTML = replace(newHTML, '</body>', scriptBlock + '</body>');
    else
        newHTML = newHTML + scriptBlock;
    end

    % 7) Write out the final HTML file
    fid = fopen(outputFile, 'w');
    fwrite(fid, newHTML);
    fclose(fid);

    % fprintf('Wrote responsive Plotly HTML to "%s"\n', outputFile);
end