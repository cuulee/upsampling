%% Create Sparse Instance Depth - KITTI
close all
clear all

img_idx = 107;
root_dir = 'H:/data_kitti_bev/2012_object';
data_set = 'training';
image_dir = fullfile(root_dir,[data_set '/image_02/data']);
label_dir = fullfile(root_dir,[data_set '/label_02']);
calib_dir = fullfile(root_dir,[data_set '/calib']);

P = readCalibration(calib_dir, img_idx, 2);
objects = readLabels(label_dir, img_idx);
depth = double(imread(strcat(root_dir, '/', data_set, '/proj_depth/velodyne_raw/image_02/', sprintf('%06d.png', img_idx))))/256.0;
[height, width, ~] = size(depth);
u = double(repmat((1:width), height,1));
v = double(repmat((1:height)', 1,width));
f = P(1,1);
cx = P(1,3);
cy = P(2,3);
x = depth.*(u - cx)/f;
y = depth.*(v - cy)/f;
z = depth;
X = x(depth~=0);
Y = y(depth~=0);
Z = z(depth~=0);
% xyz = [X';Y';Z']';
xyz = [x(:)'; y(:)'; z(:)']';
labelimg = uint8(zeros(height, width));
nolabelimg = uint8(zeros(height, width));
nolabelimg(depth~=0) = 255;

% obj_idx = 1;
for obj_idx=1:numel(objects)
%     [corners, face_idx] = computeBox3D(objects(obj_idx), P);
%     orientation = computeOrientation3D(objects(obj_idx), P);
    object = objects(obj_idx);
    [corners, face_idx] = bevkitti_computeBox3D(object);
    [k, vol] = convhulln(corners');
    corners3d{obj_idx} = corners';
    tris{obj_idx} = k;
    
    inh = inhull(xyz, corners', k);
    isin = reshape(inh, [height, width]);
    labelimg(isin) = obj_idx;
    nolabelimg(isin) = 0;
end
imwrite(labelimg, strcat(root_dir, '/', data_set, '/instance/sparse/', sprintf('%06d.png', img_idx)));
imwrite(nolabelimg, strcat(root_dir, '/', data_set, '/instance/sparse/', sprintf('%06dnolabel.png', img_idx)));

labelimgdil = imdilate(labelimg, strel('diamond', 2));
labelimgvis = ind2rgb(uint8(256*normalization(labelimgdil, 'default' , double(numel(objects)), 0.0)), prism(256));
[labelimgvisR, labelimgvisG, labelimgvisB] = imsplit(labelimgvis);
labelimgvisR(labelimgdil==0) = 255;
labelimgvisG(labelimgdil==0) = 255;
labelimgvisB(labelimgdil==0) = 255;
labelimgvis = cat(3, labelimgvisR, labelimgvisG, labelimgvisB);
imwrite(labelimgvis, strcat(root_dir, '/', data_set, '/instance/sparse_colored/', sprintf('%06d.png', img_idx)));
