%   @ henrik.skibbe
function [imgRGB,cmapping,rgb_c] = pipeline_colorize_label3D(img)

%%
labels = unique(img(:));

nlabels = numel(labels);

colorids = [1 : nlabels];
if true
colorids=([colorids(1:2:end),colorids(2:2:end)]);
colorids=([colorids(1:2:end),colorids(2:2:end)]);
colorids=([colorids(1:2:end),colorids(2:2:end)]);
colorids=([colorids(1:2:end),colorids(2:2:end)]);
colorids=([colorids(1:2:end),colorids(2:2:end)]);
end

shape = size(img);


rgb_c = squeeze(hsv2rgb(mod(2*colorids,numel(colorids)) / nlabels,0.5 + 0.5*(1-(colorids(end:-1:1) / nlabels)),0.5+0.5*(mod(5*colorids,numel(colorids))/ nlabels)));


imgn = changem(img,colorids,labels);
cmapping = [colorids',labels];

try 
    imgRGB = ind2rgb(imgn(:,:),rgb_c);
catch
    fprintf('error mapping colors .. ');
    fprintf('setting everything to zero ');
    imgRGB = zeros(single([size(img),3]));
end


imgRGB = (reshape(imgRGB,([shape,3])));

mask = ~(img==0);
for a=1:3
imgRGB(:,:,:,a)  = squeeze(imgRGB(:,:,:,a)) .* mask;
end






