function [Gss, Gds, Gss_e, Gds_e] = Get_interseismic_vels_cycle(Segs,dips,Ld,Cd,xystats,...
                      H1,H2,tR1,tR2,T,timeEq,get_SS,get_DS,Nterms)

                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  [Gss, Gds] = Get_interseismic_vels_cycle(Segs,dips,Ld,Cd,xystats,...
%                      H1,H2,tR1,tR2,T,timeEq,get_SS,get_DS)build_layered_cycle_greens.m
%
%  This function builds the greens functions response for periodic
%  earthquakes on rectangular faults in an elastic 
%  layer overlying a (Maxwell) viscoelastic layer over a (Maxwell) viscoelastic 
%  half space. Outputs are velocites at specified time and specified
%  locations. This computes the response to steady backslip on the fault
%  (to cancel the long-term rate and lock the fault) plus periodic
%  earthquakes.
%
%  INPUTS:  
%
%  H1 =  thickness of elastic layer  (km)
%  H2 =  depth to bottom of viscoelastic layer -- km -- (same as top of half-space)
%  tR1 = relaxation time (2*eta/mu, eta=viscosity, mu=shear modulus) of viscoelastic layer -- years
%  tR2 = relaxation time of viscoelastic halfspace -- years
%  T = vector of earthquake recurrence times (years) -- one for each
%      rectangular section  (NOTE:  NaN indicates no earthquakes and no viscoelastic effect --
%      compute only elastic response to back slip)
%  timeEq  =  vector of times since last earthquake (years) one for each
%      rectangular segment NOTE:  NaN indicates no earthquakes and no viscoelastic effect --
%      compute only elastic response to back slip)
%  Ends =  matrix of Endpoints of surface trace of rectangular segments (km)
%          each row is a segment:  x1  x2  y1  y2  (where x is East, y is
%          north and 1 and 2 refer to first and second endpoint)
%  dips =  vector of segment dips (degrees) using right-hand rule (positive
%          dip down to right when facing from endpoint1 to endpoint2)
%  Ld = vector of locking depths (creep at constant stress below)
%  Cd = vector of creepding depth (crep at steady rate above to surface)
%          Cd=0 if no surface creep; of course Ld>=Cd
%  xystats = Nx2 matrix of (x,y) coordinates of N observation points
%  get_SS = vector of ones and zeros, specifying whether or not to
%           calculate contribution from strike-component of slip
%           (1=yes, 0=no) -- if 'no', returns NaN
%  get_DS = vector of ones and zeros, specifying whether or not to
%           calculate contribution from dip-component of slip
%           (1=yes, 0=no) -- if 'no', returns NaN
%  Nterms = number of terms in numerical Hankel transform (default=100 if not
%           specified)
%
%  OUTPUTS:
%
%  Gss = 3NxM vector of velocities at N observation points for M
%        rectangular sources (unit strike-slip rate imposed on each source)
%        Gss(1:end/3) = east component
%        Gss(1+end/3:2*end/3) = north component
%        Gss(1+2*end/3:end) = vertical component
%
%  Gds = same as above for unit dip-slip rate imposed on each source
%
%  Kaj Johnson, Indiana University, 2007-2012, last modified Jan. 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if nargin<14
    Nterms=[];
end



xloc = [xystats';zeros(1,size(xystats,1))];
get_SS = logical(get_SS);
get_DS = logical(get_DS);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%segment geometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 centers = [(Segs(:,1)+Segs(:,3))/2 (Segs(:,2)+Segs(:,4))/2];
%calculate strike of segments
angle=atan2(Segs(:,4)-Segs(:,2),Segs(:,3)-Segs(:,1));
strike=90-angle*180/pi;
SegLength = sqrt( (Segs(:,4)-Segs(:,2)).^2 + (Segs(:,3)-Segs(:,1)).^2 );

%get center of bottom segment

%this next part is only necessary for dipping faults

%get center of bottom segment
widths=H1./sin(dips*pi/180);
temp=abs(widths).*cos(dips*pi/180);
xoffset=-temp.*cos(pi/2+angle);
yoffset=-temp.*sin(pi/2+angle);
bottcenters=centers+[xoffset yoffset];

%get center of top segment
% widths=Cd./sin(dips*pi/180);
% temp=abs(widths).*cos(dips*pi/180);
% xoffset=-temp.*cos(pi/2+angle);
% yoffset=-temp.*sin(pi/2+angle);
% topcenters=centers+[xoffset yoffset];


%get center of bottom of locked section
widths=Ld./sin(dips*pi/180);
temp=abs(widths).*cos(dips*pi/180);
xoffset=-temp.*cos(pi/2+angle);
yoffset=-temp.*sin(pi/2+angle);
bottcenters_locked=centers+[xoffset yoffset];



%get vector normal to plane
StrikeVec=[cos(angle) sin(angle) 0*angle];
DipVec=[bottcenters-centers -H1*ones(size(bottcenters,1),1)];
NormalVec=cross(StrikeVec,DipVec,2);
for k=1:size(NormalVec,1)
    NormalVec(k,:)=NormalVec(k,:)/norm(NormalVec(k,:));
    DipVec(k,:)=DipVec(k,:)/norm(DipVec(k,:));
end



Gss=zeros(3*size(xystats,1),size(centers,1));
Gds=zeros(3*size(xystats,1),size(centers,1));


for k=1:size(centers,1)  %loop over number of segments
    
        W = (Ld(k)-Cd(k))./sin(dips(k)*pi/180);  %width of locked part
        
        %strike-slip contribution 
        m_ss=[SegLength(k) W Ld(k)+0.001 dips(k) strike(k) bottcenters_locked(k,1) bottcenters_locked(k,2) 1 0 0];
        %dip-slip contribution 
        m_ds=[SegLength(k) W Ld(k)+0.001 dips(k) strike(k) bottcenters_locked(k,1) bottcenters_locked(k,2) 0 1 0];
     
      

    if isnan(T(k))  %elastic part only
           
             if get_SS(k)  %only compute if requested -- it is expensive to compute and not use 
                Uss = backslip_elastic3D(m_ss,xloc);
             else
                Uss = zeros(3,size(xloc,2));
             end

             if get_DS(k)  %only compute if requested -- it is expensive to compute and not use 
                  Uds = backslip_elastic3D(m_ds,xloc);
             else
                  Uds = zeros(3,size(xloc,2));
             end
             
    else  %compute viscoelastic and elastic parts
        
            if get_SS(k)  %only compute if requested -- it is expensive to compute and not use 
                Uss=backslip_cycle3D_layered(m_ss,xloc,H1,H2,1,1,timeEq(k),tR1,tR2,T(k),Nterms);
            else
                Uss = zeros(3,size(xloc,2));
            end
        
            if get_DS(k)  %only compute if requested -- it is expensive to compute and not use 
                Uds=backslip_cycle3D_layered(m_ds,xloc,H1,H2,1,1,timeEq(k),tR1,tR2,T(k),Nterms);
            else
                Uds = zeros(3,size(xloc,2));
            end
        
        
     end %if isnan(T(k))
     
  
    Uss_e = backslip_elastic3D(m_ss,xloc);  %ealstic only solution
    Uds_e = backslip_elastic3D(m_ds,xloc);
    
    Gss(:,k)=[Uss(1,:)';Uss(2,:)';Uss(3,:)'];
    Gds(:,k)=[Uds(1,:)';Uds(2,:)';Uds(3,:)'];
    
    Gss_e(:,k)=[Uss_e(1,:)';Uss_e(2,:)';Uss_e(3,:)'];
    Gds_e(:,k)=[Uds_e(1,:)';Uds_e(2,:)';Uds_e(3,:)'];
  
   % disp(['completed ' num2str(k/size(centers,1)*100) '% of cycle contribution.'])
     
end %for k=1:size(centers,1)





%Gss = sum(Gss,2);
%Gds = sum(Gds,2);


