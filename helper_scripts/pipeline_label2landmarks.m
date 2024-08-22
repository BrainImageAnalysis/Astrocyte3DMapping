%   @ henrik.skibbe
function M = ishii_pipeline_label2landmarks(labels2D)

ul = unique(labels2D(:));


if numel(ul)>1
    t=1;
end
ul(ul==0)=[];

shape = size(labels2D);


[X, Y] = meshgrid(1:shape(2),1:shape(1));

M = [];
for a = 1:numel(ul)
    l = ul(a);
    mask_ = labels2D==l;
    
    maskL=bwlabeln(mask_);
    mask_l = unique(maskL(:));
    mask_l(mask_l==maskL(1))=[];
    
    for b = 1:numel(mask_l)
        mask = maskL==mask_l(b);
        comX = mean(X(mask(:)));
        comY = mean(Y(mask(:)));
        v = sum(mask(:));
        %figure(14);imagesc(mask);
        M = [M ; [l,v, comX, comY, shape(1), shape(2)]];
    end
end



