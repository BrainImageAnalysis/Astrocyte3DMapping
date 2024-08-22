%   @ henrik.skibbe
function create_mesh_img_v2(mask,all_marker_pos_in_mask,all_marker_pos,fn,flip,isbrain,pscale,marker_color)



if flip
   mask = mask(end:-1:1,:,:);
end

mask = imdilate(mask,strel('sphere',5));

[x,y,z] = cylinder(1,10);
%[x,y,z] = cylinder(1,8);
pcylinder=surf2patch(x,y,z,z); 
%%
figure(1);
vert_data=ntracker_viewer_meshfrommask(mask,[1,0,0,1]);


    
[x y z] = sphere(16); 
pssphere=surf2patch(x,y,z,z);
pssphere.vertices(:,:)=pssphere.vertices(:,:)+0.5;
smallspherenormals2=-compute_vnormals2(pssphere,false,false); 
    


PATCHES=pcylinder;

PATCHES.faces=double(vert_data.f+1)';%repmat(PATCHES.f,num_connections,1);
PATCHES.vertices=double(vert_data.v)';%repmat(PATCHES.vertices,num_connections,1);
PATCHES.facevertexcdata=double(PATCHES.vertices);
PATCHES.facevertexcdata(:,1) = 3/255;
PATCHES.facevertexcdata(:,2) = 227/255;
PATCHES.facevertexcdata(:,3) = 252/255;

PATCHES_NORMALS=double(vert_data.n)';


alphas = [0,0.5,1,0.5];
for alpha_ = 1:4
    alpha = alphas(alpha_);
    %%
    f = figure(10);
    clf
   

    set(gcf, 'Renderer','OpenGL'); 
    set (gca, 'Clipping', 'on','SortMethod','depth');
    if alpha_ == 4
        set(gca,'Color','w')    
    else
        set(gca,'Color','k')    
    end
    


    surface_alpha = alpha;

    cl = [3/255,227/255,252/255];
    PATCHES.facevertexcdata(:,:) = repmat([cl],size(PATCHES.facevertexcdata,1),1);
    patch(PATCHES,'FaceVertexCData',PATCHES.facevertexcdata,...
        'FaceColor','interp','EdgeColor','none','FaceAlpha',surface_alpha,'VertexNormals',PATCHES_NORMALS,...
        'AmbientStrength',0.1,...
        'DiffuseStrength',0.25,...
        'SpecularStrength',0.1,...
        'BackFaceLighting','reverselit');


    markger_m = all_marker_pos_in_mask;
    sp = all_marker_pos(:,markger_m);
    
    if nargin>=8
        mc = marker_color(:,markger_m);
    end

    if flip
       sp(1,:) = size(mask,1) - sp(1,:); 
    end

    for a =1:size(sp,2)

        p2=pssphere;
        p2.vertices=pscale*p2.vertices;
        posv=sp(:,a)';
        %posv(2) = posv(2) - 200;

        p2.vertices=p2.vertices+repmat(posv([3,2,1]),size(pssphere.vertices,1),1);


       p_alpha = 1-alpha;
       if p_alpha == 0.5
           p_alpha  = 1;
       end
       if nargin>=8
       color=mc(:,a)';
       p = patch(p2,'FaceColor',color,'EdgeColor','none','FaceAlpha',p_alpha,...
            'VertexNormals',smallspherenormals2,...
                'DiffuseStrength',0.9,...
            'SpecularStrength',0.1,...%                'SpecularStrength',0.9,...
            'AmbientStrength',0.25);  
       else
       color=[0.95,0.95,0.95];
       p = patch(p2,'FaceColor',color,'EdgeColor','none','FaceAlpha',p_alpha,...
            'VertexNormals',smallspherenormals2,...
                'DiffuseStrength',0.5,...
                'SpecularStrength',0.9,...
            'AmbientStrength',0.1);  
       end
        

    end

    override_axis_shape = size(mask);
    axis([1 override_axis_shape(3) 1 override_axis_shape(2) 1 override_axis_shape(1)]);
    daspect([1,1,1])
   



    %axis off
     lighting phong
    %view([0,1,0]);
    %view(0,0)
    if isbrain
        view(160,40)
    else

        view(180,0)
    end
    camup([1,0,0])
    axis tight
    
    if alpha_ ~= 4
        axis off
       

        camlight; 

        li = light("Style","infinite","Position",[-10 100 0]);


        set(gcf, 'InvertHardCopy', 'off'); 
        set(gcf,'Color',[0 0 0]);
    else
        camlight; 

        li = light("Style","infinite","Position",[-10 100 0]);


        set(gcf, 'InvertHardCopy', 'off'); 
        set(gcf,'Color',[0 0 0]);
        
        set(gcf, 'InvertHardCopy', 'off'); 
        set(gcf,'Color',[1 1 1]);
    end

    %%
    res = [2000,2000];
    switch alpha_
        case 1
            save_figure(res,[fn,'_A.png'],f);
        case 2
            save_figure(res,[fn,'_C.png'],f);
        case 3
            save_figure(res,[fn,'_B.png'],f);
        case 4
            if false
            %%
            hold all
            %quiver3(0,0,-max(zlim),0,0,2*max(zlim),'b','LineWidth',1)
            %quiver3(0,-max(ylim),0,0,2*max(ylim),0,'b','LineWidth',1)
            %quiver3(-max(xlim),0,0,2*max(xlim),0,0,'b','LineWidth',1)
            
            xl=xlim
            yl=ylim
            zl=zlim
            %quiver3(xl(1),yl(1),zl(1),xl(1)+(xl(2)-xl(1))/10,yl(1),zl(1),'r','LineWidth',2)
            quiver3(xl(1),yl(1),zl(1),(xl(2)-xl(1))/10,0,0,'r','LineWidth',2)
            quiver3(xl(1),yl(1),zl(1),0,(yl(2)-yl(1))/10,0,'r','LineWidth',2)
            quiver3(xl(1),yl(1),zl(1),0,0,(zl(2)-zl(1))/10,'r','LineWidth',2)
            %text(0,0,max(zlim),'Z','Color','b')
            %text(0,max(ylim),0,'Y','Color','b')
            text(xl(1)+(xl(2)-xl(1))/10,yl(1),zl(1),'X','Color','b')
            text(xl(1),yl(1)+(yl(2)-yl(1))/10,zl(1),'Y','Color','b')
            text(xl(1),yl(1),zl(1)+(zl(2)-zl(1))/10,'Z','Color','b')
                        end
            
            
            save_figure(res,[fn,'_D.png'],f,'stretch',false);
            
    end
   
end

imgA = single(imread([fn,'_A.png']))/255;
imgB = single(imread([fn,'_B.png']))/255;
merged = max(imgA*0.85,imgB);
imwrite(merged,[fn,'_merged.png']);




