%   @ henrik.skibbe
function tissuecute_Nagai_slice_map_to_slice_Allen_std(id,slice_folder,ext)
%%

if nargin<3
    ext = 'png';
end

scale = 0.5;
delete_tmp_files = true;


%%

try     
    %%
    ants_apply = './bin/antsApplyTransforms';
    db_folder='./data/database/';
    db_tmp = './data/tmp/';
    %%
    
    ref = load_untouch_nii([db_folder,id,'/3D/c1/img3D_vis_TC_org.nii.gz']);
    low_res_shape = size(ref.img);

    ifolder = [db_folder,id,'/2D/',slice_folder,'/'];

    %%
    ofolder = [db_tmp,id,'/'];
    ofolder3D = [db_tmp,id,'/'];
    img_in = [ofolder,'/img_',slice_folder,'.nii'];
    img_out = [ofolder3D,'/img_',slice_folder,'to_Allen_std.nii'];


    mkdir(ofolder);
    %%
    if ~exist(img_in,'file')
        %%
    
        files = dir([ifolder,'/*.',ext]);
        assert(numel(files)>0)
        for a=1:numel(files)
            fprintf('%d %d\n',a,numel(files));
           img = imread([ifolder,'/',files(a).name]);
           if a == 1
              shape2D = size(img); 
              new_shape2D = ceil(scale*shape2D);
              img3D = zeros([new_shape2D,numel(files)],'uint16'); 

           end
           img3D(:,:,a) = myimresize(img,new_shape2D,'bilinear');
        end


        img2 = ref;
        img2.hdr.dime.dim(2:4) = size(img3D);
        res_fact = size(ref.img)./size(img3D);
        img2.hdr.dime.pixdim(2:4) = img2.hdr.dime.pixdim(2:4).*res_fact;
        img2.img = img3D;
        Mold = [img2.hdr.hist.srow_x;img2.hdr.hist.srow_y;img2.hdr.hist.srow_z;0,0,0,1];
        Mscale = [res_fact(1),0,0,0;0,res_fact(2),0,0;0,0,res_fact(3),0;0,0,0,1];
        
        Mnew = Mold*Mscale;
        Mnew(abs(Mnew(:))<0.00000001) = 0;

        img2.hdr.hist.srow_x = Mnew(1,:);
        img2.hdr.hist.srow_y = Mnew(2,:);
        img2.hdr.hist.srow_z = Mnew(3,:);
%%
        save_untouch_nii(img2,[ofolder,'/img_',slice_folder,'.nii']);


        clear data2 img3D
    end
    %%

    mkdir(ofolder3D);

    %%

    trafo = [db_folder,'/',id,'/3D/reg/trafo.nii.gzComposite.h5'];



    img_ref = ['/disk/k_raid/usr/skibbe-h/kato/allen_avg/P56_Atlas_highres_template.nii'];
    interp_type = 'Linear';
    %%

    T = @(img_in,img_out,interp_type)system(['ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=10  ',ants_apply,' --float -v 1 -i ',img_in,...
    ' -o ',img_out,' -r ',img_ref,' -n ',interp_type,' -t ',trafo]);
    [status,result] = T(img_in,img_out,interp_type);
    %%
    if status ~= 0
       fprintf('%s \n',result);
       assert(status==0); 
    end
    %%

    img_mapped = load_untouch_nii(img_out);


    %%
    


    %%
    ofolder = [db_folder,id,'/2D/reg/',slice_folder,'/'];
    

    mkdir(ofolder);
    %%
    for y = 1:size(img_mapped.img,2)
        %img2D = squeeze(img_mapped.img(:,:,y));

        img2D = squeeze(img_mapped.img(:,y,:));
        img2D = imrotate(img2D(end:-1:1,:),90);
        o_slice_name = ['slice',num2str(10000+y-1),'.png'];
        
        fprintf('writing file %d/%d ...',y,size(img_mapped.img,2));
        
        imwrite(uint16(min(max(img2D,0),2^16-1)),[ofolder,o_slice_name]);
        fprintf('done \n');  
    end
    

    %%
    ls(img_in)
    ls(img_out)
    rm_file1 = ['rm ',img_in];
    rm_file2 = ['rm ',img_out];
    if delete_tmp_files
        system(rm_file1);
        system(rm_file2);
        assert(~exist(img_in,'file'));
        assert(~exist(img_out,'file'));
    else
        fprintf('not deleting tmp files\n');
    end

catch ME
    fprintf('an error occured: %s\n',ME.message);
    for s=1:numel(ME.stack)
        fprintf('file: %s\nname: %s\nline: %d\n',ME.stack(s).file,ME.stack(s).name,ME.stack(s).line)
    end;
    if usejava('jvm') && ~feature('ShowFigureWindows')
        exit(1);
    end;
end;

