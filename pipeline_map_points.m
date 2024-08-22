%
%   maps the detected cell locations to the 
%   3D image space and the Allen template
%   @ henrik.skibbe
function pipeline_map_points(id)
%%
    addpath helper_scripts
    ants = './bin/antsApplyTransformsToPoints ';

    database = ['./data/database/',id,'/'];
    mfn = [database,'/meta/marker_coordinates.csv'];
    if exist(mfn,'file')
        marker = importdata(mfn);
    else
        marker = importdata([database,'/meta/marker_coordinates.xlsx']);
    end  

    %%
    ref_ = [database,'/3D/c3/img3D_vis_TC_org.nii.gz'];
    ref = load_untouch_nii(ref_);

    ref_std_ = [database,'/3D/reg/c3/img3D_vis_TC_org_to_allen.nii.gz'];
    ref_std = load_untouch_nii(ref_std_);
    %%
    high_res = 1.38;
    low_res = 25;
    valid = ~isnan(marker.data(:,1));
    pos = round(marker.data(valid,[2,1,3])./[low_res,low_res,1]);
    pos_mu = ref.edges(1:3,1:3)*pos'+ref.edges(1:3,4);
    %%
    pos_mu_ = cat(1,pos_mu,ones([1,size(pos_mu,2)]));
    pos_mu_array = round(pinv(ref.edges)*pos_mu_)+1;
    shape = size(ref.img);
    indx = sub2ind(shape,pos_mu_array(1,:),pos_mu_array(2,:),pos_mu_array(3,:));

    marker_img = ref;
    marker_img.img(:) = 0;
    marker_img.img(indx) = 1;

    tmp = marker_img.img;
    D = bwdist(tmp>0);
    
    allen_org = load_untouch_nii([database,'/3D/reg/allen/P56_Atlas.nii.gz']);
    mask = single(allen_org.img>10);

    marker_img.img = uint16(exp(-D.^2/2.5)*255.*mask);
    marker_img.hdr.dime.cal_min = 0;
    marker_img.hdr.dime.cal_max = 255;

    save_untouch_nii(marker_img,[database,'/meta/marker_org.nii.gz']);
    
    marker_img.img = uint16(exp(-D.^2/5)*255.*mask);
    marker_img.hdr.dime.cal_min = 0;
    marker_img.hdr.dime.cal_max = 255;

    save_untouch_nii(marker_img,[database,'/meta/marker_org_large.nii.gz']);
    
    

    %%

    pos_mu_ants = pos_mu.*[-1,-1,1]';
    pos_mu_ants = cat(1,pos_mu_ants,ones([1,size(pos_mu_ants,2)]));
    MTR_titles = {'x' 'y' 'z' 't'};
    C = [MTR_titles; num2cell(pos_mu_ants')];
    pts_in = [database,'/meta/marker_org_ants.csv'];
    writecell(C,pts_in);
    %%
    pts_out = [database,'/meta/marker_std_ants.csv'];
    trafo = [database,'/3D/reg/trafo.nii.gzInverseComposite.h5'];
    
    cmd = [ants,' -d 3 -i ',pts_in,' -o ',pts_out,' -t ',trafo];
    result = system(cmd);
    assert(result==0)
    marker_std_ants = importdata(pts_out);
    %%
    marker_std = marker_std_ants.data;%(:,1:2)
    marker_std(:,1:2) = -marker_std(:,1:2);
    pos_std = pinv(ref_std.edges)*marker_std';

    %%
    pos_std_ = round(pos_std(1:3,:)+1);
    shape = size(ref_std.img);

    valid = min(pos_std_>0,[],1) & min(pos_std_<=shape'); 


    indx = sub2ind(shape,pos_std_(1,valid),pos_std_(2,valid),pos_std_(3,valid));


    %%
    marker_img = ref_std;
    marker_img.img(:) = 0;
    marker_img.img(indx) = 1;

    tmp = marker_img.img;
    %sphere = strel('sphere',2);
    D = bwdist(tmp>0);
    %marker_img.img = max(min(mhs_smooth_img(tmp,1.5),1),0);
    marker_img.hdr.dime.bitpix = 8;
    marker_img.hdr.dime.datatype = 2;

    
    allen_std = load_untouch_nii(['./allen_avg/P56_Atlas.nii.gz']);
    mask = single(allen_std.img>10);
    marker_img.img = uint8(255*(mask.*exp(-D.^2/2.5)));
    marker_img.hdr.dime.cal_min = 0;
    marker_img.hdr.dime.cal_max = 1;
    marker_img.hdr.dime.scl_inter = 0;
    marker_img.hdr.dime.scl_slope = 1/255;

    save_untouch_nii(marker_img,[database,'/meta/marker_std.nii.gz']);
    
    
    mask = single(allen_std.img>10);
    marker_img.img = uint8(255*(mask.*exp(-D.^2/5)));
    marker_img.hdr.dime.cal_min = 0;
    marker_img.hdr.dime.cal_max = 1;
    marker_img.hdr.dime.scl_inter = 0;
    marker_img.hdr.dime.scl_slope = 1/255;

    save_untouch_nii(marker_img,[database,'/meta/marker_std_large.nii.gz']);

%%





