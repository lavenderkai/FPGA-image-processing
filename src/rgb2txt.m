clc
close all

I_rgb = imread('lena512color.tiff');
I_gray = rgb2gray(I_rgb);

% 保存三通道RGB数据
I_resize_2 = imresize(I_rgb,[512 640],'nearest');
[m,n,c] = size(I_resize_2);
fid2 = fopen('lena_rgb_3.txt','wt');
for i=1:m
    for j = 1:n
        for k = 1:c
            fprintf(fid2,'%02X\n',I_resize_2(i,j,k));
        end
    end
end

% 加入控制信号
for a = 1:n
    for b = 1:3
       fprintf(fid2,'%02X\n',rem(a,255));
    end
end
fclose(fid2);
