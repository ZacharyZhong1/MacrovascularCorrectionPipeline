% Mapping OEF based on CBF and R2P measurements
% Constructed by Xiaole Zhong
% Last updated: 28 July, 2023
clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
InputDirGeneral='../Preprocessed/';
OutputDirGeneral='../Preprocessed/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(InputDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Main computing loop
for Sub=20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    
    InputDir=[InputDirGeneral 'Sub' num2str(Sub)];
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    cd(OutputDir);
    
    %% Resample Coronal Scan to T1 space
    % Resample the centerdia file
    InputFile='inset MRV_CoronalT1_centerdia_clean.nii.gz';
    OutputFile='prefix MRV_CoronalT1_centerdia_resampled.nii.gz -';
    Command=strcat('3dresample -overwrite -master T1_bet.nii.gz -rmode NN -',OutputFile,InputFile);
    system(Command);
    % Resample the vessel mask
    InputFile='inset MRV_CoronalT1_newVed_Thr_clean.nii.gz';
    OutputFile='prefix MRV_CoronalT1_newVed_Thr_clean_resampled.nii.gz -';
    Command=strcat('3dresample -overwrite -master T1_bet.nii.gz -rmode NN -',OutputFile,InputFile);
    system(Command);
    
    %% Resample Sagittal Scan to T1 space
    % Resample the centerdia file
    InputFile='inset MRV_SagittalT1_centerdia_clean.nii.gz';
    OutputFile='prefix MRV_SagittalT1_centerdia_resampled.nii.gz -';
    Command=strcat('3dresample -overwrite -master T1_bet.nii.gz -rmode NN -',OutputFile,InputFile);
    system(Command);
%     Temp=MRIread('MRV_SagittalT1_centerdia_resampled.nii.gz');
%     Temp.vol=flip(Temp.vol,2);
%     MRIwrite(Temp,'MRV_SagittalT1_centerdia_resampled.nii.gz');
%     clear Temp
    % Resample the vessel mask
    InputFile='inset MRV_SagittalT1_newVed_Thr_clean.nii.gz';
    OutputFile='prefix MRV_SagittalT1_newVed_Thr_clean_resampled.nii.gz -';
    Command=strcat('3dresample -overwrite -master T1_bet.nii.gz -rmode NN -',OutputFile,InputFile);
    system(Command);
%     Temp=MRIread('MRV_SagittalT1_newVed_Thr_clean_resampled.nii.gz');
%     Temp.vol=flip(Temp.vol,2);
%     MRIwrite(Temp,'MRV_SagittalT1_newVed_Thr_clean_resampled.nii.gz');
%     clear Temp
    
    %% Combine Coronal and Sagittal Scan
    % Combine Vascular Mask
    CoronalStruct=MRIread('MRV_CoronalT1_newVed_Thr_clean_resampled.nii.gz');
    SagittalStruct=MRIread('MRV_SagittalT1_newVed_Thr_clean_resampled.nii.gz');
    EnhancedStruct=MRIread('T1_bet.nii.gz');
    EnhancedStruct.vol=max((CoronalStruct.vol),SagittalStruct.vol);
    MRIwrite(EnhancedStruct,'MRV_Mask_Enhanced.nii.gz');
    
    % Combine Centerdia
    CoronalStruct=MRIread('MRV_CoronalT1_centerdia_resampled.nii.gz');
    SagittalStruct=MRIread('MRV_SagittalT1_centerdia_resampled.nii.gz');
    EnhancedStruct=MRIread('T1_bet.nii.gz');
    EnhancedStruct.vol=max(CoronalStruct.vol,SagittalStruct.vol);
    MRIwrite(EnhancedStruct,'MRV_Centerdia_Enhanced.nii.gz');
    
    cd('../../Code/');
end

