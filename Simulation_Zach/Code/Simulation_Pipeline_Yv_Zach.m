% Use this MATLAB file to simulate venous signak
% Author: Xiaole Zhong 
% Created at: Sept 30 2020
% Last updated: March 21 2024

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
InputDirGeneral='../../Vessel_Seperation_Zach/Seperated_Vessels/';
OutputDirGeneral='../SimulatedB0Map_Yv/';
SignalDir='../Yv/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(InputDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Basic Parameter
Yvein=0.6;     % 60% oxygenation for vein
Ytissue=0.85;  % Equivalent to 85% blood oxygenation
B0=3;   % 3T main magnetic field
UpsampleFactor=4;
ZeroPaddingFactor=1/2;

%% Main-loop
for Sub=15:NumSub
    disp(['Sub:' num2str(Sub)])
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    % InputSignal
    SignalFileName=[SignalDir 'Sub' num2str(Sub) '_Yv.mat'];
    load(SignalFileName);
    
    % Import venous map
    InputDir=[InputDirGeneral 'Sub' num2str(Sub)];
    VeinStruct=MRIread([InputDir '/Venous_Mask.nii.gz']);
    VeinMapLow=VeinStruct.vol;
    
    disp('Updampling Venous Mask...')
    [xi,yi,zi] = meshgrid(1:VeinStruct.width,1:VeinStruct.height,1:VeinStruct.depth);
    [xo,yo,zo] = meshgrid(1:(VeinStruct.width-1)/(VeinStruct.width*UpsampleFactor):VeinStruct.width-1/UpsampleFactor,...
        1:(VeinStruct.height-1)/(VeinStruct.height*UpsampleFactor):VeinStruct.height-1/UpsampleFactor,...
        1:(VeinStruct.depth-1)/(VeinStruct.depth*UpsampleFactor):VeinStruct.depth-1/UpsampleFactor);
    VeinMap=interp3(xi,yi,zi,VeinMapLow,xo,yo,zo,'nearest');
    VeinMap=logical(VeinMap);
    clear xi yi zi xo yo zo VeinMapLow
    VeinMap=VeinMap(1:VeinStruct.height*UpsampleFactor-1,1:VeinStruct.width*UpsampleFactor-1,1:VeinStruct.depth*UpsampleFactor-1);
    
    disp('Generating kernel...')
    S=size(VeinMap)-3;
    [X_mat,Y_mat,Z_mat]=meshgrid(1:VeinStruct.width*UpsampleFactor+S(2)*2.*ZeroPaddingFactor-1,...
        1:VeinStruct.height*UpsampleFactor+S(1)*2.*ZeroPaddingFactor-1,...
        1:VeinStruct.depth*UpsampleFactor+S(3)*2.*ZeroPaddingFactor-1);
    X=single(X_mat-ceil((VeinStruct.width*UpsampleFactor+S(2)*2.*ZeroPaddingFactor-1)/2));
    clear X_mat
    Y=single(Y_mat-ceil((VeinStruct.height*UpsampleFactor+S(1)*2.*ZeroPaddingFactor-1)/2));
    clear Y_mat
    Z=single(Z_mat-ceil((VeinStruct.depth*UpsampleFactor+S(3)*2.*ZeroPaddingFactor-1)/2));
    clear Z_mat 
    R=sqrt(X.^2+Y.^2+Z.^2);
    clear X Y 
    % Kernel
    Kernel=1/(4*pi)*((3*Z.^2-R.^2)./(R.^5));
    Kernel(isnan(Kernel))=0;
    clear R Z 
    
    for iteration=1:1
        disp(strcat('Iteration:',num2str(iteration)))
        
        % Susceptibility of vain and tissue 
        YveinTC=Yvein+Yvein*0.30*Yv;   % Oxygenated level variation
        KaiVein=0.27e-6*0.4*(1-YveinTC)*4*pi;    % Susceptibility of vein
        KaiTissue=0.27e-6*0.4*(1-Ytissue)*4*pi;  % Susceptibility of tissue
        KaiAir=KaiTissue;
        
        % Create output file
        B0Struct=VeinStruct;
        B0Struct.height=VeinStruct.height.*UpsampleFactor-1;
        B0Struct.width=VeinStruct.width.*UpsampleFactor-1;
        B0Struct.depth=VeinStruct.depth.*UpsampleFactor-1;
        B0Struct.vox2ras=[.7 .7 .7]./UpsampleFactor;
        B0Struct.vox2ras0(1,1)=0.7./UpsampleFactor;
        B0Struct.vox2ras0(2,2)=0.7./UpsampleFactor;
        B0Struct.vox2ras0(3,3)=0.7./UpsampleFactor;
        B0Struct.vox2ras=B0Struct.vox2ras0;
        B0Struct.vox2ras1=B0Struct.vox2ras0;
        B0Struct.tkrvox2ras(1,1)=-0.7./UpsampleFactor;
        B0Struct.tkrvox2ras(2,3)=0.7./UpsampleFactor;
        B0Struct.tkrvox2ras(3,2)=-0.7./UpsampleFactor;
        B0Struct.volsize=[VeinStruct.height.*UpsampleFactor-1,VeinStruct.width*UpsampleFactor-1,VeinStruct.depth.*UpsampleFactor-1];
        B0Struct.vol=zeros(B0Struct.height,B0Struct.width,B0Struct.depth);
        a=B0Struct.height;
        b=B0Struct.width;
        c=B0Struct.depth;

        for Time=1:length(Yv)
            disp(strcat('Time Points:',num2str(Time)))
            KaiMap=single((VeinMap).*(KaiVein(Time)-KaiTissue)+KaiAir);
            KaiMap=padarray(KaiMap,[S(1).*ZeroPaddingFactor S(2).*ZeroPaddingFactor S(3).*ZeroPaddingFactor],KaiTissue,'both');

         
            % Fourier transfrom and calculate k-space magnetic field offset
            KKaiMap=fftn((KaiMap));
            clear KaiMap
            KKernel=fftn((Kernel));

            B0OffsetKSpace=(KKaiMap).*(KKernel);
            clear KKernel KKaiMap
            B0OffsetTemp=ifftn((B0OffsetKSpace));
            clear B0OffsetKSpace
            B0Offset=B0.*ifftshift(B0OffsetTemp);
            clear B0OffsetTemp
            B0Struct.vol(:,:,:)=(B0Offset(S(1).*ZeroPaddingFactor+1:end-S(1).*ZeroPaddingFactor,S(2).*ZeroPaddingFactor+1:end-S(2).*ZeroPaddingFactor,S(3).*ZeroPaddingFactor+1:end-S(3).*ZeroPaddingFactor));
            clear B0Offset
            %Output the B0 offset map
            FileOut=[OutputDir '/VenousB0MapIteration_',num2str(iteration),'Frame_',num2str(Time),'.nii.gz'];
            MRIwrite(B0Struct,FileOut);
%             B0Struct.vol(:,:,:)=zeros(1,1,1);
%             clear B0Struct.vol
        end
        
    end
end
