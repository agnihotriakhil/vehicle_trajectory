clear all, clc; close all;

%%
copy = true;
primitive_root = '../data/primitives_labeled';

if ~exist(primitive_root, 'dir')
    mkdir(primitive_root);
end

cluster_sizes_savepath = strcat(primitive_root, '/cluster_sizes.mat');

if exist(cluster_sizes_savepath, 'file')
    cluster_sizes = load(cluster_sizes_savepath);
    cluster_sizes = cluster_sizes.cluster_sizes;
else
    cluster_sizes = [];
end

num_of_cluster = length(cluster_sizes);

fig = figure;
for cls = 1:num_of_cluster
    for fi = 1:3
        fn_primitive = strcat(primitive_root, '/', num2str(cls), '/primitive_', num2str(fi), '_dense.mat');
        if exist(fn_primitive, 'file')
            primitive_read = load(fn_primitive);
            primitive_dense = primitive_read.enc_dense;
            ax_example = subplot(3, num_of_cluster, num_of_cluster*(fi-1) + cls);
            title(strcat('class ', num2str(cls), ':', num2str(fi)))
            cla(ax_example);
            hold(ax_example, 'on');
            plot(ax_example, primitive_dense{1}(1,:), primitive_dense{1}(2,:),'.');
            plot(ax_example, primitive_dense{2}(1,:), primitive_dense{2}(2,:),'.');
            hold(ax_example, 'off');
            axis equal;
        end
    end
end

fig1 = figure;
ax = axes(fig1);

source_dir = '../data/primitives_wy_raw/';
filePattern = fullfile(source_dir, '*.mat');
flist = dir(filePattern);

for fi = 1:length(flist)
    
    fn = flist(fi).name;
    label_path = strcat(primitive_root, '/', fn(1:end-4), '.txt');
    
    if exist(label_path, 'file')
        fileID = fopen(label_path,'r');
        cls = fscanf(fileID,'%d'); fclose(fileID);
        fprintf('%s -> %d Done.\n', fn, cls);
        continue;
    end
    
    source = strcat(source_dir, fn);
    [cls, enc_dense, valid] = ConvertAndLabel(ax, source, cluster_sizes);
    
    if ~valid
        fprintf('%s Invalid.\n', fn);
        continue;
    end
    if isempty(cls)
        fprintf('Skipped...\n');
        fileID = fopen(label_path, 'w');
        fprintf(fileID, '%d', -1); fclose(fileID);
        continue;
    end
    
    if length(cluster_sizes) < cls
        cluster_sizes = [cluster_sizes 0];
    end
    if cls > length(cluster_sizes)
        cls = length(cluster_sizes);
        fprintf('Corrected to %d\n', cls);
    end
    
    fileID = fopen(label_path, 'w');
    fprintf(fileID, '%d', cls); fclose(fileID);
    
    cluster_sizes(cls) = cluster_sizes(cls) + 1;
    save(cluster_sizes_savepath, 'cluster_sizes');
    
    primitive_path4cls = strcat(primitive_root, '/', num2str(cls));
    if ~exist(primitive_path4cls, 'dir')
        mkdir(primitive_path4cls);
    end
    destination = strcat(primitive_path4cls, '/primitive_', num2str(cluster_sizes(cls)), '_dense.mat');
    save(destination, 'enc_dense');
    saveas(fig1, strcat(primitive_path4cls, '/', num2str(cluster_sizes(cls)), '__', fn(1:end-4), '.png'));
    
    fprintf(strcat('Saved', destination, '\n'));
end

display('Conversion done');

%%
function [cls, primitive_dense, valid] = ConvertAndLabel(ax, source, cluster_sizes)

    cls = -1;
    primitive_dense = {};
    valid = true;
    enc_raw = load(source);
    enc_raw = enc_raw.primitive;
    
    enc_w1 = [enc_raw(:,2)';enc_raw(:,1)'];
    enc_w2 = [enc_raw(:,5)';enc_raw(:,4)'];
    
    if ~isValid(enc_w1, enc_w2)
        valid = false;
        return
    end
    
    % primitive_dense = {};
    [enc_x_w1, enc_y_w1, meridian_rad, offset_x, offset_y, ~, ~] = latlon2xy_origin_scale(enc_w1(1,:), enc_w1(2,:));
    [enc_x_w2, enc_y_w2, ~, ~, ~, ~] = latlon2xy_origin_scale(enc_w2(1,:), enc_w2(2,:), meridian_rad, offset_x, offset_y);
    
    [primitive_dense{1}, valid1] = WayInterpolation([enc_x_w1; enc_y_w1], 1, false);
    [primitive_dense{2}, valid2] = WayInterpolation([enc_x_w2; enc_y_w2], 1, false);

    concatXY = [primitive_dense{1} primitive_dense{2}];
    
    mean_x = mean(concatXY(1,:), 2);
    mean_y = mean(concatXY(2,:), 2);

    primitive_dense = {primitive_dense{1} - [mean_x; mean_y], primitive_dense{2} - [mean_x; mean_y]};

%     concatXY = concatXY - [mean_x; mean_y];

    if ~valid1 || ~valid2
        valid = false;
        return;
    end
    
    cla(ax);
    hold(ax, 'on');
    plot(ax, primitive_dense{1}(1,:), primitive_dense{1}(2,:),'.');
    plot(ax, primitive_dense{2}(1,:), primitive_dense{2}(2,:),'.');
    hold(ax, 'off');
    axis(ax, 'equal');
    
    cls = input(sprintf(strcat('---------------------------\n',...
                        source, ...
                        '\nChoose 1 to %d, or skip: '), length(cluster_sizes)));
    cls = int8(cls);
    
    return
end

function ret = isContinuous(x)
    diff_vector = x(1:end-1) - x(2:end);
    f = find(diff_vector > 0.001); % GPS coordinate
    if size(f, 2) > 0
        ret = false;
        return
    end
    ret = true;
    return
end

function ret = isValid(enc_w1, enc_w2)
    if size(find(enc_w1(1,:)==180), 2) > 0 || size(find(enc_w2(1, :)==180), 2) > 0
        ret = false;
    end
    
    ret = isContinuous(enc_w1(1,:)) && isContinuous(enc_w1(2,:)) &&...
            isContinuous(enc_w2(1,:)) && isContinuous(enc_w2(2,:));
    
end