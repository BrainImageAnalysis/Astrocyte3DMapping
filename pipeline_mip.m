%   @ henrik.skibbe
%%
db = './data/';

%%

atlas_bg = load_untouch_nii(['./allen_avg/P56_Atlas.nii.gz']);
atlas_ = load_untouch_nii(['./allen_avg/P56_Annotation.nii.gz']);
%%
atlas_bg = single(atlas_bg.img);
atlas_bg = atlas_bg /max(atlas_bg(:));

atlas = atlas_.img;

%%

fn_labels = './allen_avg/labels.txt';
labels = importdata(fn_labels);
labels = cellfun(@(x)strsplit(x,'|'),labels,'UniformOutput',false);
labels = cellfun(@(x)x([1,4,5]),labels,'UniformOutput',false);
%%

%%
mask = zeros(size(atlas));
for r =1:numel(region_ids)
   rd = region_ids(r);
   fprintf('%s / %s\n',labels{rd}{1},labels{rd}{3}); 
   mask = mask | (atlas == str2num(labels{rd}{1}));
end
%%

           
%%
markers_ram1 = load_untouch_nii([db,'/database/RAM#1/meta/marker_std.nii.gz']);
markers_gibla = load_untouch_nii([db,'/database/Gi_BLA/meta/marker_std.nii.gz']);
markers_nonrecal = load_untouch_nii([db,'/database/non_recal#2/meta/marker_std.nii.gz']);
markers_gilc = load_untouch_nii([db,'/database/Gi_LC/meta/marker_std.nii.gz']);
markers_prop = load_untouch_nii([db,'/database/PROP/meta/marker_std.nii.gz']);

marks = {markers_ram1, markers_gibla, markers_nonrecal, markers_gilc, markers_prop};
titles = {'ram#1','Gi_BLA','non_recal#2','Gi_LC','PROP'};


all_marker_pts = {'/database/RAM#1/meta/marker_std_ants.csv',...
              '/database/Gi_BLA/meta/marker_std_ants.csv',...
              '/database/non_recal#2/meta/marker_std_ants.csv',...
              '/database/Gi_LC/meta/marker_std_ants.csv',...
              '/database/PROP/meta/marker_std_ants.csv',...
                };
            
%%


markers_nonrecal3 = load_untouch_nii([db,'/database/Non-recall#3/meta/marker_std.nii.gz']);
marks = {markers_nonrecal3};
titles = {'Non-recall#3'};


all_marker_pts = {'/database/Non-recall#3/meta/marker_std_ants.csv',...
                };
            
            
%%            
all_marker_indx = {};
all_marker_pos = {};
all_marker_pos_in_mask = {};
 for mid = 1:numel(marks)          
    marker_std_ants = importdata([db,all_marker_pts{mid}]);
    marker_std = marker_std_ants.data;%(:,1:2)
    marker_std(:,1:2) = -marker_std(:,1:2);
    pos_std = pinv(atlas_.edges)*marker_std';
    pos_std_ = round(pos_std(1:3,:)+1);
    shape = size(atlas_.img);
    valid = min(pos_std_>0,[],1) & min(pos_std_<=shape'); 
    indx = sub2ind(shape,pos_std_(1,valid),pos_std_(2,valid),pos_std_(3,valid));
    all_marker_indx{mid} = indx;
    all_marker_pos{mid} = pos_std_(:,valid);
 end


%%

do_3D = true;

for mid = 1:numel(marks)
%for mid = 1:1
    %%
    markers = marks{mid};
    %%
    for r = 1:6
       

        exact_match = true;
        
        switch r
            case 1
            postfix = 'HCP';
            region = {'CA1','CA2','CA3','DG-mo','DG-po','DG-sg'};
            case 2
            %STR
            postfix = 'STR';
            region = {'CP','ACB'};
            %break
            case 3
            %BLA
            postfix = 'BLA';
            region = {'BLAa','BLAp','LA','BLAv'};
            case 4
            %
            postfix = 'VIS';
            region = {'VISp1','VISp2/3','VISp4','VISp5','VISp6a','VISp6b'};    
            case 5
            %
            postfix = 'ALL';
            region = {'VISp1','VISp2/3','VISp4','VISp5','VISp6a','VISp6b','BLAa','BLAp','LA','BLAv','CP','ACB','CA1','CA2','CA3','DG-mo','DG-po','DG-sg'};    
            case 6
            postfix = 'BRAIN';
            region = {};    
          %  break
        end

        if exact_match 
            find_label = @(y)find(cellfun(@(x)strcmpi(x{3},y),labels));
            region_ids  = cellfun(find_label,region);
        else
        %%
           find_label = @(y)find(cellfun(@(x)contains(x{3},y)&(~contains(x{3},'VISC')),labels));  
           region_ids  = cellfun(find_label,region,'UniformOutput',false);
           region_ids = [region_ids{:}];
           for a = 1:numel(region_ids)
              fprintf('%s\n',labels{region_ids(a)}{3}) 
           end

        end
        
        for m = 1:2
            mask = zeros(size(atlas));
            if numel(region_ids)>0
                for r =1:numel(region_ids)
                   rd = region_ids(r);
                   fprintf('%s / %s\n',labels{rd}{1},labels{rd}{3}); 
                   mask = mask | (atlas == str2num(labels{rd}{1}));
                end
            else
                if m==2
                   break 
                end
                mask = atlas>0;
            end

            % also include points that are on the edge of a region 
            mask = imdilate(mask,strel('sphere',5));

            if numel(region_ids)>0
                if m == 1
                    postfix2 = '_0';
                    flip = false;
                    mask(1:end/2,:,:) = 0;
                else
                    postfix2 = '_1';
                    flip = true;
                    mask(end/2:end,:,:) = 0;
                end
            else
                postfix2 = '';
                flip= false;
            end

            MIP = squeeze(max(single(markers.img).*mask,[],2));
            MIP2 = squeeze(max(single(markers.img).*(~mask),[],2));
            MIP = MIP/(max(MIP(:))+0.00001);
            MIP2 = MIP2/max(MIP2(:)+0.00001);
            MIPmask = squeeze(max(mask,[],2))*0.45;
            MIP_RGB = cat(3,MIP,max(MIP,MIPmask),max(MIP,MIPmask));
            sfigure(mid);
            imagesc(imrotate(MIP_RGB,90))
            title(titles{mid});
            drawnow

            all_marker_pos_in_mask{mid} = mask(all_marker_indx{mid});
            
            fprintf('%d\n',sum(mask(all_marker_indx{mid})));
            
            if do_3D 

            fn = ['./data/figs/img_',titles{mid},'_',postfix,postfix2];
            pscale = 0.85;
            pscale = 2.0;
            create_mesh_img_v2(mask,all_marker_pos_in_mask{mid},all_marker_pos{mid},fn,flip,numel(region_ids)==0,pscale);
            
            end
        end
    end
end
%%


