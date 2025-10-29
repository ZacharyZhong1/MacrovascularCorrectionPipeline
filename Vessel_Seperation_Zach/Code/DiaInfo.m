% Use this MATLAB file to segment Vein 
% Author: Xiaole Zhong 
% Created at: Sept 30 2020
% Last updated: Sept 30 2020

clc;
clear;
block=1;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
InputDirGeneral='../../Vessel_Segementation_Zach/Preprocessed/';
MaskDirGeneral='../Seperated_Vessels/';

all_files=dir(InputDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Create folder for raw fMRI data 
for Sub=1:20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    InputDir=[InputDirGeneral 'Sub' num2str(Sub)];
    InputFile=[InputDir '/MRV_Centerdia_Enhanced.nii.gz'];

    DiaInStruct=MRIread(InputFile);

    MaskDir=[MaskDirGeneral 'Sub' num2str(Sub)];
    MaskFile=[MaskDir '/Venous_Mask.nii.gz'];
    
    MaskInStruct=MRIread(MaskFile);

    MaskDia=DiaInStruct.vol.*MaskInStruct.vol;
    DiaList(Sub)=nanmean(MaskDia(MaskDia~=0));
end