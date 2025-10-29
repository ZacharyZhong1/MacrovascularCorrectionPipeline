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
BOLDDirGeneral='../../fMRI_Signal_Zach/Preprocessed/'; % Please change to your own fMRI data folder
OutputDirGeneral='../Simulated_Mask/';
InfoDirGeneral=OutputDirGeneral;
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(T1DirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;


for Sub=6:20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    
    InfoDir=[InfoDirGeneral 'Sub' num2str(Sub)];
    fileID = fopen([InfoDir '/PaddingMask_New.txt'],'r');
    formatSpec = '%d';
    sizeA = [1 Inf];
    PaddingT1New = fscanf(fileID,formatSpec,sizeA);
    fclose(fileID);
        
    fileID = fopen([InfoDir '/PaddingBOLD.txt'],'r');
    formatSpec = '%d';
    sizeA = [1 Inf];
    PaddingBOLD = fscanf(fileID,formatSpec,sizeA);
    fclose(fileID);
    
    disp('Inputing and turncating brain mask...')

    FileIn=[InfoDir '/BrainMask.nii.gz'];
    BrainMaskStruct=MRIread(FileIn);
    BrainMask=BrainMaskStruct.vol;
    BrainMask=BrainMask(PaddingT1New(3)+1:PaddingT1New(4)+4,...
        PaddingT1New(1)+1:PaddingT1New(2)+4,...
        PaddingT1New(5)+1:PaddingT1New(6)+4);
    
    disp('Inputing and turncating venous mask...')

    FileIn=[InfoDir '/VenousMask.nii.gz'];
    VenousMaskStruct=MRIread(FileIn);
    VenousMask=VenousMaskStruct.vol;
    VenousMask=VenousMask(PaddingT1New(3)+1:PaddingT1New(4)+4,...
        PaddingT1New(1)+1:PaddingT1New(2)+4,...
        PaddingT1New(5)+1:PaddingT1New(6)+4);

    BOLDBrainMaskStruct=MRIread([InfoDir '/mask_BOLD_autobox.nii.gz']);
    BOLDBrainMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
    BOLDVenousMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
    Height=BOLDBrainMaskStruct.height;
    Width=BOLDBrainMaskStruct.width;
    nSlices=BOLDBrainMaskStruct.depth;
    
    
    disp('Outputing BOLD space data...')  
        
    for h=1:Height
        for w=1:Width
            for s=1:nSlices
                SubBrainMask=BrainMask((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                SubVenousMask=VenousMask((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                VoxelSize=25*20*20;
                VesselVolume=sum(sum(sum(SubVenousMask)));
                BrainVolume=VoxelSize-VesselVolume;
                fBV(h,w,s)=VesselVolume/VoxelSize;
            end
        end
    end

    OutputFile=MRIread([InfoDir '/BrainMaskBOLD.nii.gz']);
    OutputFile.vol=zeros(OutputFile.height,OutputFile.width,OutputFile.depth);
    OutputFile.vol(PaddingBOLD(3)+1:PaddingBOLD(4)+1,PaddingBOLD(1)+1:PaddingBOLD(2)+1,PaddingBOLD(5)+1:PaddingBOLD(6)+1)...
        =fBV;
    MRIwrite(OutputFile,[OutputDir '/BOLD_VenousfBV.nii.gz']);
    clear fBV

end
