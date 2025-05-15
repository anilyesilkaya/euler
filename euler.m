src = 'test.mlx';

 [~,name,ext] = fileparts(src);

switch ext
    case '.mlx'
        % Run the src file
        matlab.internal.liveeditor.executeAndSave([name ext]);
        fprintf('Ran the MLX file "%s"\n', [name ext])

        % Convert MLX to HTML
        matlab.internal.liveeditor.openAndConvert([name ext], [name '.html']);
        fprintf('Converted the MLX file to HTML: "%s" to "%s"\n', [name ext], [name '.html']);

        % Convert Base64 PNG images to Plotly interactive plots
        convertBase64PNGToPlotly([name '.html'], [name '_plotly.html']);
        fprintf('Converted the base 64 PNGs to Plotly plots: "%s" to "%s"\n', [name '.html'], [name '_plotly.html']);
    otherwise
        error("Unsupported file type it should be MLX.")
end

