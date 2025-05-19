classdef dynamicPlot < handle
    properties
        plotData = {};
        exportData = struct();
        count = 1;
    end
    methods
        function plot(obj, varargin)
            obj.plotData{obj.count} = struct('type', 'plot', 'args', {varargin});
            plot(varargin{:});
            obj.exportData = { struct('x', varargin(1), 'y', varargin(2), 'type', 'scatter', 'mode', 'lines') };
            obj.saveJSON();
            obj.count = obj.count + 1;
        end
    end

    methods(Access=private)
        function saveJSON(obj)
            jsonData = jsonencode(obj.exportData);
            fid = fopen(sprintf('plot_%d.json',obj.count), 'w');
            if fid == -1
                return
            end
            fwrite(fid, jsonData, 'char');
            fclose(fid);
        end
    end
end