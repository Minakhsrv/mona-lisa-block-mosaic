% MONALISA_BLOCKS  Render an image as a mosaic of directional tiles.
%
% Each pixel of the input image is replaced by a 32x32 tile chosen by the
% local Sobel gradient direction (up / down / left / right). The tile's
% brightness is then adjusted to match the source pixel, so the tiles
% "draw" the edges of the original image.
%
% Requires: MATLAB (or GNU Octave) with the Image Processing Toolbox
%           (imgradientxy, imgradient, rgb2gray, imresize).
%
% Usage:    run monalisa_blocks.m   (from any folder)

clear; close all; clc;

%% 0. Configuration
root        = fileparts(mfilename('fullpath'));
input_file  = fullfile(root, 'assets', 'mona_lisa.png');
block_dir   = fullfile(root, 'assets', 'blocks');
output_file = fullfile(root, 'results', 'monalisa_final.png');

block_names = {'block_up.png', 'block_down.png', 'block_left.png', 'block_right.png'};
block_size  = [32, 32];   % tile size in pixels
threshold   = 0.5;        % splits dark / bright regions
dark_adj    = 0.9;        % how much dark tile areas are lightened (bright pixels)
bright_adj  = 0.6;        % offset used to darken tiles (dark pixels)

%% 1. Load the source image
img = imread(input_file);
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = im2double(img);     % values in [0, 1]

%% 2. Load and prepare the tiles
blocks = cell(1, 4);
for k = 1:4
    blk = imread(fullfile(block_dir, block_names{k}));
    if size(blk, 3) == 3
        blk = rgb2gray(blk);
    end
    blocks{k} = im2double(imresize(blk, block_size));
end

%% 3. Gradient direction (Sobel)
[Gx, Gy] = imgradientxy(img, 'sobel');
[~, direction] = imgradient(Gx, Gy);   % direction in degrees, (-180, 180]

%% 4. Build the mosaic
[rows, cols] = size(img);
output_image = zeros(rows * block_size(1), cols * block_size(2));

for i = 1:rows
    for j = 1:cols
        theta = direction(i, j);

        % Pick the tile from the gradient direction
        if theta > -45 && theta <= 45
            tile = blocks{4};            % right
        elseif theta > 45 && theta <= 135
            tile = blocks{2};            % down
        elseif theta < -45 && theta >= -135
            tile = blocks{1};            % up
        else
            tile = blocks{3};            % left
        end

        pixel_val   = img(i, j);
        dark_mask   = tile < threshold;
        bright_mask = ~dark_mask;

        if pixel_val < threshold
            % Dark pixel: darken both parts of the tile
            tile(dark_mask)   = tile(dark_mask)   * (pixel_val + bright_adj);
            tile(bright_mask) = tile(bright_mask) * (pixel_val + 0.2);
        else
            % Bright pixel: lighten only the dark parts of the tile
            tile(dark_mask) = tile(dark_mask) + pixel_val * dark_adj;
        end

        tile = min(tile, 1);             % clamp to [0, 1]

        r = (i - 1) * block_size(1) + 1;
        c = (j - 1) * block_size(2) + 1;
        output_image(r:r + block_size(1) - 1, c:c + block_size(2) - 1) = tile;
    end
end

%% 5. Show and save
figure; imshow(output_image); title('Mona Lisa - block mosaic');
if ~exist(fileparts(output_file), 'dir'), mkdir(fileparts(output_file)); end
imwrite(output_image, output_file);
