%   @ henrik.skibbe
function pipeline_nifit_2_slice(varargin)
try    
   

isatlas = false;
landmarks = false;
intensities_16bit = false;
threshold = -1;
iscolorimg = false;

ifile = '';    
trafo = @(x)x;
for k = 1:2:length(varargin),
        eval(sprintf('%s=varargin{k+1};',varargin{k}));
end;
%%

if (exist(ifile,'file') && exist(ofolder,'dir'))


    img = load_untouch_nii(ifile);
    

    img = trafo(single(img.img));
    
    

    fprintf('threshold: %f\n',threshold);
    if (threshold>0)
       img = single(img>threshold);
    end
    
    if iscolorimg
        imgRGB = img;
    else
        
        if isatlas 
            fprintf('mapping colors .. ');
            imgRGB = pipeline_colorize_label3D(uint32(img));
            fprintf('done');

        else
            if ~intensities_16bit
                img = img-min(img(:));
                img = img./(max(img(:)) + 0.00000001);
                imgRGB = cat(4, img, img, img);
            else
                assert(~isatlas)
            end

        end
    end

    shape = size(img);
    %%
    count = 0;
    for a = 1:shape(3)
       %%
       ofile = [ofolder,'/slice',num2str(10000+count),'.png']; 
       fprintf('%s\n', ifile ); 
       
       if ~intensities_16bit
        slicer = squeeze(imgRGB(:,:,a,:));
       else
        slicer = squeeze(uint16(img(:,:,a)));   
       end

       %%
       fprintf('writing %s\n', ofile ); 
       imwrite(slicer,ofile);

       %%
     
       if (landmarks)
           
        slicer_I = squeeze(img(:,:,a));
        M = pipeline_label2landmarks(slicer_I);
        ofile_LM = [ofolder,'/slice',num2str(10000+count),'.csv']; 
        csvwrite(ofile_LM,M);
       end

        count  = count +1;


    end
    %%

else
    if ~(exist(ifile,'file'))
        fprintf('the file %s does not exist\n', ifile ); 
    end
    if ~(exist(ofolder,'dir'))
        fprintf('the folder %s does not exist\n', ofolder ); 
    end
    
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
    
       