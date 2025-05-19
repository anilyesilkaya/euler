function eulerBuild(sourceFile)
    arguments
        sourceFile {mustBeText}
    end

    close all
    clear figureDynamic
    addpath('assets\')
    addpath('notebooks\')
    addpath('scripts\')
    
     [path,name,ext] = fileparts(sourceFile);
     assert(~isempty(name), "File cannot be found.")
    
    switch ext
        case '.mlx'

            % Run the src file
            fprintf('\n\x1b[34m┌────────────────────────────────────────────────────────┐\x1b[0m\n\n');
            matlab.internal.liveeditor.executeAndSave(which([fullfile(path,name) ext]));
            fprintf('  \x1b[36m🏃  Ran MLX:\x1b[0m %s\n\n', fullfile(path, [name ext]));
    
            % Convert MLX to HTML
            matlab.internal.liveeditor.openAndConvert(which([fullfile(path,name) ext]), [fullfile(path,name) '.html']);
            fprintf('  \x1b[36m🔄  Converted MLX → HTML:\x1b[0m "%s" → "%s"\n\n', ...
                        fullfile(path, [name ext]), fullfile(path, [name '.html']));
    
            % Convert Base64 PNG images to Plotly interactive plots
            convertBase64PNGToPlotly([fullfile(path,name) '.html'], [fullfile(path,name) '.html']);
    
            % Make the code blocks nicer
            convertMATLABCodeToStylish([fullfile(path,name) '.html'], [fullfile(path,name) '_final.html']);
    
            % Final display
            fprintf('  \x1b[32m✅  Euler build complete:\x1b[0m %s\n\n', fullfile(path, [name '_final.html']));

            % View the file in local browser
            hypertext = sprintf('<a href="http://localhost:8000/notebooks/%s_final.html">%s_final.html</a>', name, name);
            fprintf('\n  [\x1b[4mView Page\x1b[0m]   %s\n\n', hypertext);
            fprintf('\x1b[34m└────────────────────────────────────────────────────────┘\x1b[0m\n\n');
        otherwise
            error("Unsupported file type it should be MLX.")
    end

end

