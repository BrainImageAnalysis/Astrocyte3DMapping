%   @ henrik.skibbe
function tissuecute_make_nii_mouse(ifile,ofile,varargin)

fprintf('making nifti for mouse data\n');

mid='';
pid = feature('getpid');
fprintf('MATLAB PID: %d\n',pid);

[pathstr, name, ext]=fileparts([mfilename('fullpath'),'.m']);
addpath(pathstr);

voxel_size = [0.025,0.025,0.05];

pipeline_2_0 = true;


for k = 1:2:length(varargin),
            eval(sprintf('%s=varargin{k+1};',varargin{k}));
end;

try 
%%
    if ischar(ifile)
        Img=ishii_pipeline_readtif(ifile);
    else
        Img=ifile;    
    end
%%


    

    
    nifti = make_nii(uint16(max(floor(Img),0)),voxel_size, [0,0,0], 512, mid);

     if exist('loadtrafo','var')
       fprintf('using existing trafo\n');  
   
       load(loadtrafo);   
     else
       
    
        shape = size(Img);    
         
         
        wx=reshape(sum(sum(Img,2),3),[1,shape(1)]);
        wy=reshape(sum(sum(Img,1),3),[1,shape(2)]);
        wz=reshape(sum(sum(Img,1),2),[1,shape(3)]);
        rot_origin= [ ...
                  sum([1:shape(1)].*wx)/sum(wx) ...
                  sum([1:shape(2)].*wy)/sum(wy) ...
                  sum([1:shape(3)].*wz)/sum(wz) ...
                ];

        S=eye(4);
        S(1:3,1:3)=diag(voxel_size);

        T=eye(4);
        T(1:3,4)=rot_origin;
        Tinv=eye(4);
        Tinv(1:3,4)=-rot_origin;
        
        R_base=euler_rot(3*pi/2,pi/2,0);
        
        R=eye(4);
        Mirrow=eye(4);
        Mirrow(1,1)=-1;
        %M=S*Mirrow*R_base*R*Tinv;
        M=Mirrow*R_base*R*Tinv*S;
        M(abs(M(:))<0.0000001) = 0;
     end
    
    
     
    nifti.hdr.hist.sform_code = 1;
    nifti.hdr.hist.srow_x(1:4)=M(1,:);
    nifti.hdr.hist.srow_y(1:4)=M(2,:);
    nifti.hdr.hist.srow_z(1:4)=M(3,:);
    save_nii(nifti,ofile)
    
%%    
    if exist('savetrafo','var')
       fprintf('predicting trafo %s \n',savetrafo);  
       save(savetrafo,'M','pipeline_2_0'); 
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