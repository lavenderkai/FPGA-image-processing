clc
clear

img_rgb = imread('../src/lena512color.tiff');
img_rgb = imresize(img_rgb,[512 640]);
img_gray = rgb2gray(img_rgb);

fid = fopen('gray_image_Y.txt','r'); %FPGA×ª»»»Ò¶ÈÍ¼Ïñ
data = fscanf(fid,'%2x');
data = uint8(data);
gray_data = reshape(data,640,512);
gray_data = gray_data';

figure,
subplot(1,3,1),imshow(img_rgb);
subplot(1,3,2),imshow(img_gray);
subplot(1,3,3),imshow(gray_data);