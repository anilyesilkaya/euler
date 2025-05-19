classdef eulerBuilder < handle
    properties
        inputFile
        filePath
        fileName
        fileExt
        src
        dst
        tmp
    end

    methods
        % Constructor
        function obj = eulerBuilder(inputFile)
            assert(~isempty(dir(inputFile)), "File cannot be found.");
            [path, name, ext] = fileparts(inputFile);
            obj.inputFile = inputFile;
            obj.filePath = path;
            obj.fileName = name;
            obj.fileExt = ext;
            obj.src = which([fullfile(path,name) ext]);
            obj.dst = replace(obj.src,'.mlx','.html');
            obj.tmp = obj.dst;
        end

        function build(obj)
            % Initialization
            obj.initialize();

            % Execute and export to HTML
            obj.export2html();
        end
    end

    % Private methods
    methods (Access=private)
        function initialize(~)
            addpath('../assets')
            addpath('../notebooks')
            addpath('../scripts')
        end

        function htmlText = readHTML(obj, tmpFileName)
            % Read the original HTML
            htmlText = fileread(obj.tmp);
            obj.tmp = tmpFileName;
        end

        function writeHTML(~, htmlName, htmlContent)
            % Write the modified HTML to a temporary file
            fid = fopen(htmlName, 'w', 'n', 'UTF-8');
            if fid < 0
                error('Could not open output file %s for writing.', htmlName);
            end
            fwrite(fid, htmlContent);
            fclose(fid);
        end

        function export2html(obj)
            % HTML export
            switch obj.fileExt
                case {'.mlx', '.m'}
                    % Execute the and save the output (requires absolute path of the file)
                    % Note that the plot data will be saved during this
                    % process
                    matlab.internal.liveeditor.executeAndSave(obj.src);

                    % Export MLX to HTML
                    matlab.internal.liveeditor.openAndConvert(obj.src,obj.dst);

                    % Replace the base64 PNGs with the placeholder
                    % Save it to file_tmp.html
                    obj.png2placeholder();

                    % Replace the title with the placeholder
                    obj.title2placeholder();
                    
                    % Replace codeblocks with the placeholder
                    obj.code2placeholder();
                otherwise
                    error("Only MLX and Live M files are supported.");
            end
        end

        function title2placeholder(obj)
            % Read HTML
            htmlText = obj.readHTML(replace(obj.tmp,'.html','_tmp.html'));

            % Pattern:  
            %   <h1\s+class\s*=\s*['"]S0['"]>    matches the opening tag (allowing single or double quotes around S0, and extra spaces)  
            %   <span>([^<]+)</span>              captures whatever's inside the span into group 1  
            %   </h1>                            matches the closing tag  
            pattern     = '<h1\s+class\s*=\s*[''"]S0[''"]>\s*<span>([^<]+)</span>\s*</h1>';
            
            % Replacement:  
            %   {{TitlePlaceholder: $1}}         injects the captured text ($1) into your placeholder  
            replacement = '{{TitlePlaceholder: $1}}';

            newHtml = regexprep(htmlText, pattern, replacement);

            % Write new HTML file
            obj.writeHTML(obj.tmp, newHtml);
        end

        function code2placeholder(obj)
            % Read HTML
            htmlText = obj.readHTML(replace(obj.tmp,'.html','_tmp.html'));
            
            %Regex to capture non-greedy between div.inlineWrapper (with optional extra classes)
            % (?s) makes '.' match newline
            % class="inlineWrapper(?:\s+[^"]*)?" matches:
            %   class="inlineWrapper"           (no extras)
            % or class="inlineWrapper outputs"  (or any other extra classes)
            pattern = '(?s)<div\s+class="inlineWrapper(?:\s+[^"]*)?">(.*?)</div>';
            
            % Extract all full matches and inner tokens
            allMatches = regexp(htmlText, pattern, 'match');   % full <div…>…</div>
            allTokens  = regexp(htmlText, pattern, 'tokens');  % { {'inner1'}, {'inner2'}, … }
            
            if isempty(allMatches)
                warning('No matching <div class="inlineWrapper">…</div> blocks found.');
            end
            
            %Loop to encode & replace each occurrence once
            newHtml = htmlText;  % start from the original
            for k = 1:numel(allMatches)
                payload = allTokens{k}{1};                        % raw inner content
                % payload = matlab.net.base64encode(char(innerHTML)); % Base64-encode it
                placeholder = sprintf('{{CodePlaceholder: %s}}', payload); % build marker
                % Escape the literal match before replacing, so regexprep treats it literally
                literalMatch = regexptranslate('escape', allMatches{k});
                newHtml = regexprep(newHtml, literalMatch, placeholder, 'once');
            end

            % Write new HTML file
            obj.writeHTML(obj.tmp, newHtml);
        end

        function png2placeholder(obj)
            % Read HTML
            htmlText = obj.readHTML(replace(obj.tmp,'.html','_tmp.html'));

            % Replace the base64 PNGs with placeholders
            % Regex: (?s) turns on DOTALL so '.' matches newline
            pattern1 = ['(?s)<div[^>]*class="inlineElement eoOutputWrapper ', ...
            'disableDefaultGestureHandling embeddedOutputsFigure"[^>]*', ...
            'data-testid="output_(\d+)"[^>]*>.*?</div>'];

            % Replace all matches with the placeholder
            plotIdx = cellfun(@(x) str2double(x{:}) + 1, regexp(htmlText, pattern1, "tokens"));

            pattern2 = ['(?s)<div[^>]*class="figureElement eoOutputContent" role="article" aria-roledescription="Use Browse Mode to explore " aria-description="figure output "[^>]*?>', ...
                        '<img[^>]*src="data:image/png;base64,[^\"]*"[^>]*>.*?</div>'];

            % Replacement string
            replacement = sprintf('{{PlotPlaceholder: plot_%d}}', plotIdx);

            % Perform the replacement
            newHtml = regexprep(htmlText, pattern2, replacement);

            % Write new HTML
            obj.writeHTML(obj.tmp, newHtml);
        end
    end
end