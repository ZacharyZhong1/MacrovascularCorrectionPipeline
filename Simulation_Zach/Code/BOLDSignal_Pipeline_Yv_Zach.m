% Upsample the vascular mask and brain mask and then allign high-res space
% with BOLD space and downsample brian mask
% Author: Xiaole Zhong 
% Created at: April 1 2024
% Last updated: April 1 2024

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
OutputDirGeneral='../Simulated_Signal/BOLDSignal/';
BOLDDirGeneral='../../fMRI_Signal_Zach/Preprocessed/';
R1DirGeneral='../Simulated_Signal/R1/';
R2DirGeneral='../Simulated_Signal/R2_Yv/';
R2PDirGeneral='../Simulated_Signal/R2P_Yv/';
SignalDir='../Yv/';

if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(R2PDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;


for Sub=1:NumSub
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])

    
    OutputDir=OutputDirGeneral;
    SignalFileName=[SignalDir 'Sub' num2str(Sub) '_Yv.mat'];
    load(SignalFileName);
    NumTime=length(Yv);
    
    disp('Inputing R1...')
    R1Dir=[R1DirGeneral 'Sub' num2str(Sub)];
    FileIn=[R1Dir '/R1Iteration_',num2str(1),'Frame_',num2str(1),'.nii.gz'];
    R1Struct=MRIread(FileIn);
    Height=R1Struct.height;
    Width=R1Struct.width;
    nSlices=R1Struct.depth;
    
    disp('Inputing BOLD as output...')
    BOLDDir=[BOLDDirGeneral 'Sub' num2str(Sub)];
    FileIn=[BOLDDir '/func_smooth.nii.gz'];
    BOLDStruct=MRIread(FileIn);
    BOLDStruct.vol=BOLDStruct.vol.*0;

    
    disp('Computing signal...')
    for Time=1:NumTime 
        R2Dir=[R2DirGeneral 'Sub' num2str(Sub)];
        FileIn=[R2Dir '/R2Iteration_',num2str(1),'Frame_',num2str(Time),'.nii.gz'];
        R2Struct=MRIread(FileIn);
        
        R2PDir=[R2PDirGeneral 'Sub' num2str(Sub)];
        FileIn=[R2PDir '/R2PIteration_',num2str(1),'Frame_',num2str(Time),'.nii.gz'];
        R2PStruct=MRIread(FileIn);
        
        BOLDStruct.vol(:,:,:,Time)=R1Struct.vol.*R2Struct.vol.*R2PStruct.vol;

    end
    
    OutputFileName=[OutputDir 'Sub' num2str(Sub) '_BOLDSignal_Yv.nii.gz'];
    MRIwrite(BOLDStruct,OutputFileName);
end