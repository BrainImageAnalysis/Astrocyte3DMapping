%   @ henrik.skibbe
function vert_data=ntracker_viewer_meshfrommask(Img,color,varargin)

crop=[0,0,0]; 
element_size=[1,1,1];
reduce=4;
scaleto=-1;
smooth_input = true;
light='smooth';

for k = 1:2:length(varargin),
        eval(sprintf('%s=varargin{k+1};',varargin{k}));
end;

            
            shape=size(Img);
             if reduce>-1
                border=reduce*[3,3,3];
             else
                border=1*[3,3,3]; 
             end
            Img2=zeros(shape+2*border,'single');
            
            Img2(border(1)+1:border(1)+shape(1),border(2)+1:border(2)+shape(2),border(3)+1:border(3)+shape(3))=Img;
            
            if reduce>-1
            D=mhs_smooth_img(single(Img2),reduce,'normalize',true);
            end
            
             
            
            D(1,1,:)=0;
            D(1,:,1)=0;
            D(:,1,1)=0;
            D(end,1,:)=0;
            D(end,:,1)=0;
            D(:,end,1)=0;
            D(1,:,end)=0;
            D(1,end,:)=0;
            D(:,1,end)=0;           
            D(end,end,:)=0;
            D(end,:,end)=0;
            D(:,end,end)=0;
            
            
            %D = smooth3(Img);
            
            if (reduce>-1)
                
                [x,y,z,D] = reducevolume(D,reduce*[1,1,1]);
                %isurf=isosurface(x,y,z,D, threshold,'noshare');
                threshold=max(D(:))/2;
                p=isosurface(x,y,z,D, threshold);
            else
                threshold=max(D(:))/2;
                
                %p=isosurface(D, threshold,'noshare');
                p=isosurface(D, threshold);
            end;
                
             flat=false;
            
            
             %order=[2,1,3]; %todo ich glaub [3,1,2]
             order=[3,1,2];
             p.vertices=p.vertices(:,order);
             
             p.vertices(:,1)=p.vertices(:,1)-crop(1)-1-border(1);
             p.vertices(:,2)=p.vertices(:,2)-crop(2)-1-border(2);
             p.vertices(:,3)=p.vertices(:,3)-crop(3)-1-border(3);
            
            switch light
                case 'smooth'
                    flat=false;
                    vert_data.n=single(compute_vnormals2(p,flat,false))';
            
                otherwise 
                    flat=true;
                    vert_data.n=single(compute_vnormals2(p,flat,false))';
            end
            vert_data.v=single(p.vertices)';
            vert_data.f=uint32(p.faces(:,[3,2,1]))'-1;
            
            
            if max(abs(element_size-1))>eps    
                element_size=element_size/min(element_size);
%                  vert_data.v(1,:)=vert_data.v(1,:)*element_size(1);
%                  vert_data.v(2,:)=vert_data.v(2,:)*element_size(2);
%                  vert_data.v(3,:)=vert_data.v(3,:)*element_size(3);
                 
                 vert_data.v(1,:)=vert_data.v(1,:)*element_size(3);
                 vert_data.v(2,:)=vert_data.v(2,:)*element_size(2);
                 vert_data.v(3,:)=vert_data.v(3,:)*element_size(1);
            end;    

            
            
            if nargin>1
                assert(numel(color)==4);
                assert(size(color,1)==1);
                vert_data.color=single(color);
            end;
            
            if scaleto>0
                scaleto=scaleto/max(shape);
                 vert_data.v(1,:)=vert_data.v(1,:)*scaleto;
                 vert_data.v(2,:)=vert_data.v(2,:)*scaleto;
                 vert_data.v(3,:)=vert_data.v(3,:)*scaleto;
            end;
            
            
    
function mesh=mergeverts(mesh)                

                
D=distmat(mesh.vertices,mesh.vertices)+1000*eye(size(mesh.vertices,1));
pos=[1:size(mesh.vertices,1)];
[v,indx]=min(D);
indx2=(indx>pos);
indx3=indx2&(v==0);
keepme=pos(indx3);
replaceme=indx(indx3);

for v=1:numel(keepme)
    mesh.faces(mesh.faces(:)==replaceme(v))=keepme(v);
end;


pos_valid=pos;
pos_valid(:,replaceme)=[];
pos_new=[1:numel(pos_valid)];

if pos_valid(end)>numel(pos_valid)
    mesh.faces=mesh.faces(:,pos_valid);
    for v=1:numel(pos_new) 
           mesh.faces(mesh.faces(:)==pos_valid(v))= pos_new(v);

    end;
end;            



function vnormals=compute_vnormals(pcylinder)

               % fprintf('precomputing normals ...');
                
                vnormals=zeros(size(pcylinder.vertices));
                for a=1:size(pcylinder.faces,1)
                    %idx=pcylinder.face()
                    %snormal=cross(pcylinder.vertices(pcylinder.faces(a,1),:),pcylinder.vertices(pcylinder.faces(a,2),:));
                    n1=pcylinder.vertices(pcylinder.faces(a,2),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n1=n1/norm(n1);
                    n2=pcylinder.vertices(pcylinder.faces(a,4),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n2=n2/norm(n2);
                    snormal=cross(n1,n2);
                    if sum(isnan(snormal(:)))==0
                    for b=1:4
                        vnormals(pcylinder.faces(a,b),:)=vnormals(pcylinder.faces(a,b),:)+snormal;
                    end;
                    end;
                end;
                vnormals=vnormals./repmat(eps+sqrt(sum(vnormals.^2,2)),1,3);

function vnormals=compute_vnormals2__(pcylinder,makeflat)

               % fprintf('precomputing normals ...');
               if size(pcylinder,2)==4 
               
                vnormals=zeros(size(pcylinder.vertices));
                for a=1:size(pcylinder.faces,1)
                    %idx=pcylinder.face()
                    %snormal=cross(pcylinder.vertices(pcylinder.faces(a,1),:),pcylinder.vertices(pcylinder.faces(a,2),:));
                    n1=pcylinder.vertices(pcylinder.faces(a,2),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n1=n1/norm(n1);
                    n2=pcylinder.vertices(pcylinder.faces(a,4),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n2=n2/norm(n2);
                    snormal=cross(n1,n2);
                    if sum(isnan(snormal(:)))==0
                        for b=1:4
                            vnormals(pcylinder.faces(a,b),:)=vnormals(pcylinder.faces(a,b),:)+snormal;
                        end;
                    else
                        for b=1:4
                            vnormals(pcylinder.faces(a,b),:)=vnormals(pcylinder.faces(a,b),:)+[0,0,-1];
                        end;
                    end;
                end;
               else
                   vnormals=zeros(size(pcylinder.vertices));
                for a=1:size(pcylinder.faces,1)
                    %idx=pcylinder.face()
                    %snormal=cross(pcylinder.vertices(pcylinder.faces(a,1),:),pcylinder.vertices(pcylinder.faces(a,2),:));
                    n1=pcylinder.vertices(pcylinder.faces(a,2),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n1=n1/norm(n1);
                    n2=pcylinder.vertices(pcylinder.faces(a,3),:)-pcylinder.vertices(pcylinder.faces(a,1),:);
                    n2=n2/norm(n2);
                    snormal=cross(n1,n2);
                    
                    if sum(isnan(snormal(:)))==0
                        for b=1:3
                            vnormals(pcylinder.faces(a,b),:)=vnormals(pcylinder.faces(a,b),:)+snormal/norm(snormal);
                        end;
                    else
                        for b=1:3
                            vnormals(pcylinder.faces(a,b),:)=vnormals(pcylinder.faces(a,b),:)+[0,0,-1];
                        end;
                    end;
                end;
               end;
                
                vnormals=vnormals./repmat(eps+sqrt(sum(vnormals.^2,2)),1,3);                
                
                 DM=sqrt(distmat(pcylinder.vertices,pcylinder.vertices));
                 vnormals_new = vnormals;
                 if true
                    checked=zeros(1,size(DM,1));
                     for a=1:size(DM,1)
                         if ~checked(a)
                                 %sel=find(DM(a,:)<0.0001);
                                 %sel=find(DM(a,:)<1.0);
                                 sel=find(DM(a,:)<0.5);
                                 if numel(sel)>1
                                     %newn=mean(vnormals(sel,:));
                                     newn = (sum(vnormals(sel,:),1))/numel(sel);
                                     checked(sel)=true;
                                     newn=newn./(norm(newn)+eps);
                                     vnormals_new(sel,:)=repmat(newn,numel(sel),1);
                                 end;
                         else
                            assert(all(checked(sel==1)));
                         end;
                     end;
                 end
                 vnormals = vnormals_new;
                     
if makeflat                     
                     for n=1:size(vnormals,1)
                         vnormals(n,:)=vnormals(n,:)+5*dot(vnormals(n,:),[0,0,1])*[0,0,1];
                         vnormals(n,:)=vnormals(n,:)./norm(vnormals(n,:)+eps);
                     end;
end;                