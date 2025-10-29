% Upsample the vascular mask and brain mask and then allign high-res space
% with BOLD space and downsample brian mask
% Author: Xiaole Zhong 
% Created at: April 1 2024
% Last updated: April 1 2024

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
T1DirGeneral='../../Vessel_Segementation_Zach/Preprocessed/';
VenousDirGeneral='../../Vessel_Seperation_Zach/Seperated_Vessels/';
BOLDDirGeneral='../../fMRI_Signal_Zach/Preprocessed/';
OutputDirGeneral='../Simulated_Mask/';
SignalDir='../GMS_Signal/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(T1DirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;
UpsampleFactor=4;

for Sub=6:20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    
    %% Prepare T1 at BOLD space
    disp('Sampling T1 to BOLD space...')
    BOLDDir=[BOLDDirGeneral 'Sub' num2str(Sub)];
    BOLDRefName=[BOLDDir '/example_func.nii.gz'];
    T1Dir=[T1DirGeneral 'Sub' num2str(Sub)];
    MatFileName=[BOLDDir '/highres2func.mat'];
    InputFileName=[T1Dir '/T1_bet.nii.gz'];
    OutputFileName=[OutputDir '/BOLD_T1.nii.gz'];
    Command=['flirt -in' ' ' InputFileName ' -ref' ' ' BOLDRefName ' -dof 6 -out' ' ' ...
       OutputFileName ' -init' ' ' MatFileName ' -applyxfm'];
    system(Command);
    
    %% Make brain mask and upsample
    disp('Upsampling Brain Mask...')
    T1Struct=MRIread([T1Dir '/T1_bet.nii.gz']);
    MaskStruct=T1Struct;
    clear T1Struct
    MaskStruct.vol=logical(MaskStruct.vol);
    MaskMapLow=MaskStruct.vol;
    
    [xi,yi,zi] = meshgrid(1:MaskStruct.width,1:MaskStruct.height,1:MaskStruct.depth);
    [xo,yo,zo] = meshgrid(1:(MaskStruct.width-1)/(MaskStruct.width*UpsampleFactor):MaskStruct.width-1/UpsampleFactor,...
        1:(MaskStruct.height-1)/(MaskStruct.height*UpsampleFactor):MaskStruct.height-1/UpsampleFactor,...
        1:(MaskStruct.depth-1)/(MaskStruct.depth*UpsampleFactor):MaskStruct.depth-1/UpsampleFactor);
    MaskMap=interp3(xi,yi,zi,MaskMapLow,xo,yo,zo,'nearest');
    clear xi yi zi xo yo zo MaskMapLow
    MaskMap=MaskMap(1:MaskStruct.height*UpsampleFactor-1,1:MaskStruct.width*UpsampleFactor-1,1:MaskStruct.depth*UpsampleFactor-1);
    MaskStruct.vox2ras=[.7 .7 .7]./UpsampleFactor;
    MaskStruct.vol=MaskMap;
    MaskFileOut=[OutputDir '/BrainMask.nii.gz'];
    MRIwrite(MaskStruct,MaskFileOut);
    clear MaskStruct
    
    %% Make venous mask and upsample
    disp('Updampling Venous Mask...')
    VenousDir=[VenousDirGeneral 'Sub' num2str(Sub)];
    VenousStruct=MRIread([VenousDir '/Venous_Mask.nii.gz']);
    VenousMapLow=VenousStruct.vol;
    
    [xi,yi,zi] = meshgrid(1:VenousStruct.width,1:VenousStruct.height,1:VenousStruct.depth);
    [xo,yo,zo] = meshgrid(1:(VenousStruct.width-1)/(VenousStruct.width*UpsampleFactor):VenousStruct.width-1/UpsampleFactor,...
        1:(VenousStruct.height-1)/(VenousStruct.height*UpsampleFactor):VenousStruct.height-1/UpsampleFactor,...
        1:(VenousStruct.depth-1)/(VenousStruct.depth*UpsampleFactor):VenousStruct.depth-1/UpsampleFactor);
    VenousMap=interp3(xi,yi,zi,VenousMapLow,xo,yo,zo,'nearest');
    VenousMap=logical(VenousMap);
    clear xi yi zi xo yo zo VenousMapLow
    VenousMap=VenousMap(1:VenousStruct.height*UpsampleFactor-1,1:VenousStruct.width*UpsampleFactor-1,1:VenousStruct.depth*UpsampleFactor-1);
    VenousStruct.vox2ras=[.7 .7 .7]./UpsampleFactor;
    VenousStruct.vol=VenousMap;
    VenousFileOut=[OutputDir '/VenousMask.nii.gz'];
    MRIwrite(VenousStruct,VenousFileOut);
    clear VenousStruct  
    
    %% Copy BOLD Mask
    disp('Copying BOLD Mask...')    
    BOLDFileName=[BOLDDir '/mask.nii.gz'];
    BOLDFileOut=[OutputDir '/BrainMaskBOLD.nii.gz'];
    command=['cp' ' ' BOLDFileName ' ' BOLDFileOut];
    system(command);
    
    %% Allignment
    disp('Alligning the high-res and BOLD...')
     % Autobox Mask mask
    MaskTextFile=[OutputDir '/PaddingMask.txt'];
    AutoBoxFileMask=[OutputDir '/mask_autobox.nii.gz'];
    [status,cmdout]=system(['3dAutobox -noclust -overwrite -extent_ijk_to_file' ' ' MaskTextFile ' -prefix' ' '...
        AutoBoxFileMask ' -input' ' ' MaskFileOut]);

    % Autobox BOLD mask
    BOLDTextFile=[OutputDir '/PaddingBOLD.txt'];
    AutoBoxFileBOLD=[OutputDir '/mask_BOLD_autobox.nii.gz'];
    [status,cmdout]=system(['3dAutobox -noclust -overwrite -extent_ijk_to_file' ' ' BOLDTextFile ' -prefix' ' '...
        AutoBoxFileBOLD ' -input' ' ' BOLDFileOut]);

    % Read Autobox data 
    BOLDMask=MRIread(AutoBoxFileBOLD);
    BOLDMaskHeight = BOLDMask.height;
    BOLDMaskWidth = BOLDMask.width;
    BOLDMasknSlices = BOLDMask.depth;
    MaskMask=MRIread(AutoBoxFileMask);
    MaskMaskHeight = MaskMask.height;
    MaskMaskWidth = MaskMask.width;
    MaskMasknSlices = MaskMask.depth;

    % Read Padding info 
    fileID = fopen(MaskTextFile,'r');
    formatSpec = '%d';
    sizeA = [1 Inf];
    PaddingMaskNew = fscanf(fileID,formatSpec,sizeA);
    fclose(fileID);

    Jdiff=20*BOLDMaskHeight-MaskMaskHeight;
    Idiff=20*BOLDMaskWidth-MaskMaskWidth;
    Kdiff=25*BOLDMasknSlices-MaskMasknSlices;

    PaddingMaskNew(1)=PaddingMaskNew(1)-ceil(Idiff/2);
    PaddingMaskNew(2)=PaddingMaskNew(2)+(Idiff-ceil(Idiff/2));
    PaddingMaskNew(3)=PaddingMaskNew(3)-ceil(Jdiff/2);
    PaddingMaskNew(4)=PaddingMaskNew(4)+(Jdiff-ceil(Jdiff/2));
    PaddingMaskNew(5)=PaddingMaskNew(5)-ceil(Kdiff/2);
    PaddingMaskNew(6)=PaddingMaskNew(6)+(Kdiff-ceil(Kdiff/2));

    if PaddingMaskNew(1)<=0
        PaddingMaskNew(2)=PaddingMaskNew(2)+(0-PaddingMaskNew(1));
        PaddingMaskNew(1)=0;
    end

    if PaddingMaskNew(3)<=0
        PaddingMaskNew(4)=PaddingMaskNew(4)+(0-PaddingMaskNew(3));
        PaddingMaskNew(3)=0;
    end

    if PaddingMaskNew(5)<=0
        PaddingMaskNew(6)=PaddingMaskNew(6)+(0-PaddingMaskNew(5));
        PaddingMaskNew(5)=0;
    end

    fileID = fopen([OutputDir '/PaddingMask_New.txt'],'w');
    fprintf(fileID,'%d %d %d %d %d %d',PaddingMaskNew);
    fclose(fileID);
    
    %% Downsample Brain Mask
    disp('Downsampling brain mask and venous mask...')
    MaskStruct=MRIread(MaskFileOut);
    BrainMask=MaskStruct.vol;
    BrainMaskTruncate=BrainMask(PaddingMaskNew(3)+1:PaddingMaskNew(4)+1,PaddingMaskNew(1)+1:PaddingMaskNew(2)+1,PaddingMaskNew(5)+1:PaddingMaskNew(6)+1);
    VenousStruct=MRIread(VenousFileOut);
    VenousMask=VenousStruct.vol;
    VenousMaskTruncate=VenousMask(PaddingMaskNew(3)+1:PaddingMaskNew(4)+1,PaddingMaskNew(1)+1:PaddingMaskNew(2)+1,PaddingMaskNew(5)+1:PaddingMaskNew(6)+1);
    
    BOLDBrainMaskStruct=MRIread(AutoBoxFileBOLD);
    BOLDBrainMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
    BOLDVenousMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
    Height=BOLDBrainMaskStruct.height;
    Width=BOLDBrainMaskStruct.width;
    nSlices=BOLDBrainMaskStruct.depth;
    
    for h=1:Height
        for w=1:Width
            for s=1:nSlices
                SubBrainMask=BrainMaskTruncate((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                SubVenousMask=VenousMaskTruncate((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                if sum(SubBrainMask(:))~=0
                    BOLDBrainMask(h,w,s)=1;
                    if sum(SubVenousMask(:))~=0
                        BOLDVenousMask(h,w,s)=1;
                    end
                end
            end
        end
    end
    fileID = fopen([OutputDir '/PaddingBOLD.txt'],'r');
    formatSpec = '%d';
    sizeA = [1 Inf];
    PaddingBOLD = fscanf(fileID,formatSpec,sizeA);
    fclose(fileID);
        
    disp('Outputing BOLD space data...')
    OutputFile=MRIread(BOLDFileOut);
    OutputFile.vol=zeros(OutputFile.height,OutputFile.width,OutputFile.depth);
    OutputFile.vol(PaddingBOLD(3)+1:PaddingBOLD(4)+1,PaddingBOLD(1)+1:PaddingBOLD(2)+1,PaddingBOLD(5)+1:PaddingBOLD(6)+1)...
        =BOLDBrainMask;
    MRIwrite(OutputFile,[OutputDir '/BOLD_BrainMask.nii.gz']);
    
    OutputFile=MRIread(BOLDFileOut);
    OutputFile.vol=zeros(OutputFile.height,OutputFile.width,OutputFile.depth);
    OutputFile.vol(PaddingBOLD(3)+1:PaddingBOLD(4)+1,PaddingBOLD(1)+1:PaddingBOLD(2)+1,PaddingBOLD(5)+1:PaddingBOLD(6)+1)...
        =BOLDVenousMask;
    MRIwrite(OutputFile,[OutputDir '/BOLD_VenousMask.nii.gz']);
end

