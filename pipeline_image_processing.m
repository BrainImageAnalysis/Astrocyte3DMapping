%
%   creates 3D image stacks from tissuecyte sections
%   and uses the ANTs image registration toolkit (https://stnava.github.io/ANTs/)
%   to align them with the Allen template
%   @ henrik.skibbe
%
function pipeline_image_processing(id)
%%
raw_folder='./data/raw/';
db_folder='./data/database/';
allen_ref_folder = './allen_avg/';
allen_ref = [allen_ref_folder,'/P56_Atlas.nii.gz'];
antsApply = './bin/antsApplyTransforms';


if ~(exist([raw_folder,id,'/meta/'],'dir')==7)
   fprintf('META FILE MISSING -> SKIPPING\n');
    return; 
end
assert(exist([raw_folder,id,'/meta/'],'dir')==7);

do_3D = true;
compute_Transform = true;
apply_Transform = true;
map_atlas_to_org = true;
atlas_to_2D = true;
highres = true;

addpath helper_scripts


if do_3D
    meta_folder = [db_folder,'/',id,'/meta/'];
    mkdir(meta_folder);
    
    metadata_folder =  meta_folder;
    trafo_file = [meta_folder,'trafo.mat'];
    for channel = 1:4
        ifolder=[db_folder,'/',id,'/2D/'];
        ofolder=[db_folder,'/',id,'/3D/'];
        mkdir([ofolder,'/c',num2str(channel),'/']);
        make_my_nii = @(ifile,ofile,varargin)tissuecute_make_nii_mouse(ifile,ofile,varargin{:});
        tissuecyte_stitch_3D_2020(ifolder,ofolder,channel,'element_size_xy',[50,50]/2,'metadata_folder',[metadata_folder,'../'],'trafo_file',trafo_file,'make_my_nii',make_my_nii,'ext','tif');
    end

end

%%

if compute_Transform
    %%
     channel=1;
     ofolder_ref =[db_folder,'/',id,'/3D/reg/'];
     mkdir(ofolder_ref);
     move=[db_folder,'/',id,'/3D/c',num2str(channel),'/img3D_raw_TC_org.nii.gz'];
     out=[ofolder_ref,'/trafo.nii.gz'];
     cmd = [ './reg_2_allen.sh',...
        ' ',move,...
        ' ',allen_ref,...
        ' ',out...
     ];
     system(cmd)

end

if apply_Transform
    %%
    fnames = {};
    for channel = 1:4
        fnames{numel(fnames)+1}=[db_folder,'/',id,'/3D/c',num2str(channel),'/img3D_raw_TC_org.nii.gz'];
        fnames{numel(fnames)+1}=[db_folder,'/',id,'/3D/c',num2str(channel),'/img3D_vis_TC_org.nii.gz'];
    end
    for f=1:numel(fnames)
        %%
        move = fnames{f};
        trafo=[ofolder_ref,'/trafo.nii.gz'];
        out=[move];
        out = strrep(out,'.nii.gz','_to_allen.nii.gz');
        out = strrep(out,[db_folder,'/',id,'/3D'],[db_folder,'/',id,'/3D/reg/']);
        [filepath,name,ext] = fileparts(out);
        mkdir(filepath);

        cmd = [antsApply, ' ',...
        ' -i  ',move,...
        ' -o ',out,...
        ' -r ',allen_ref...
        ' -n Linear --float 1 -v 1 -t ',trafo,'Composite.h5',...
    ];
    system(cmd)
    end
    
end
    

if map_atlas_to_org
    
    ofolder_ref =[db_folder,'/',id,'/3D/reg/'];

    ofolder = [ofolder_ref,'/allen/'];
    mkdir(ofolder);

    fname = 'P56_Atlas.nii.gz';


    out=[ofolder,fname];
    channel  = 1;
    move= [allen_ref_folder,fname];
    fix = [db_folder,'/',id,'/3D/c',num2str(channel),'/img3D_raw_TC_org.nii.gz'];
    trafo=[ofolder_ref,'/trafo.nii.gz'];
    [filepath,name,ext] = fileparts(out);
    mkdir(filepath);

    cmd = [antsApply, ' ',...
        ' -i  ',move,...
        ' -o ',out,...
        ' -r ',fix...
        ' -n Linear --float 1 -v 1 -t ',trafo,'InverseComposite.h5',...
    ];
    system(cmd)


    fname = 'P56_Annotation.nii.gz';
    
    out=[ofolder,fname];
    channel  = 1;
    move= [allen_ref_folder,fname];
    fix = [db_folder,'/',id,'/3D/c',num2str(channel),'/img3D_raw_TC_org.nii.gz'];
    trafo=[ofolder_ref,'/trafo.nii.gz'];
    [filepath,name,ext] = fileparts(out);
    mkdir(filepath);

    cmd = [ antsApply,' ',...
        ' -i  ',move,...
        ' -o ',out,...
        ' -r ',fix...
        ' -n MultiLabel --float 1 -v 1 -t ',trafo,'InverseComposite.h5',...
    ];
    system(cmd)
end
    
    
if atlas_to_2D 
    addpath /disk/k_raid/KAKUSHIN-NOU-DATA/SOFT/pipeline/skibbe-h_rep/matlab/
    
    ofolder_base =[db_folder,'/',id,'/2D/allen/'];
    
    ifolder_ref =[db_folder,'/',id,'/3D/reg/'];
    ifolder = [ifolder_ref,'/allen/'];
    if true
        fname = 'P56_Atlas.nii.gz';

        ifile = [ifolder,fname];
        ofolder = [ofolder_base,strrep(fname,'.nii.gz','/')];
        mkdir(ofolder)
        pipeline_nifit_2_slice(...
            'ifile',ifile,...
            'ofolder',ofolder,...
            'isatlas',false);
    end
    fname = 'P56_Annotation.nii.gz';
        
    ifile = [ifolder,fname];
    ofolder = [ofolder_base,strrep(fname,'.nii.gz','/')];
    mkdir(ofolder)
    pipeline_nifit_2_slice(...
        'ifile',ifile,...
        'ofolder',ofolder,...
        'isatlas',true,'landmarks',true);

end

if highres
    tissuecute_Nagai_slice_map_to_slice_Allen_std(id,'c1','tif');
    tissuecute_Nagai_slice_map_to_slice_Allen_std(id,'c2','tif');
    tissuecute_Nagai_slice_map_to_slice_Allen_std(id,'c3','tif');
    tissuecute_Nagai_slice_map_to_slice_Allen_std(id,'c4','tif');
end

