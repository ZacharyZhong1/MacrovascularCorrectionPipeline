% Artery Segmentation
% Constructed by Xiaole Zhong
% Last updated: Oct 29 2025
clc;
clear;

%% I/O information
SubjectListFile=fileread('ParticipantFolder.txt'); % enter the folder name for each subject, seperate by Enter
SubList=strsplit(SubjectListFile);
NumSub=length(SubList);
InputDirGeneral='/rri_disks/klymene/chen_lab/data/nii/';
OutputDirGeneral='../Preprocessed/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
cd(OutputDirGeneral);

%% Main Loop
for Sub=20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    
%     InputDir=[InputDirGeneral SubList{Sub}];
    InputDir=SubList{Sub};
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    cd(OutputDir);
    %% Copy TOF From Raw Data Folder
    AngioFileIn=[InputDir '/anat-angio_acq-cor.nii.gz'];
    AngioFileOut='MRV_Coronal.nii.gz';
    copyfile(AngioFileIn,AngioFileOut)

    %% Skull-stripping
    disp('Extracting brain for T1...')
    InputFileName=[InputDir '/anat-T1w.nii.gz'];
    OutputFileName='T1_bet.nii.gz';
    system(['mri_watershed' ' ' InputFileName ' ' OutputFileName]);
    system('bet2 MRV_Coronal.nii MRV_Coronal_ss.nii.gz -m -f 0.4');
    
    %% Resample to T1 space
    disp('Registration...')
    system('flirt -in MRV_Coronal_ss.nii.gz -ref T1_bet.nii.gz -dof 6 -cost mutualinfo -out vessel2highres -omat vessel2highres.mat');
    system('flirt -in MRV_Coronal.nii -ref T1_bet.nii.gz -applyxfm -init vessel2highres.mat -out MRV_CoronalT1.nii.gz');
%     system('flirt -in MRV_Coronal.nii.gz -ref T1_bet.nii.gz -dof 6 -cost corratio -out vessel2highres -omat vessel2highres.mat');
%     system('flirt -in MRV_Coronal.nii -ref T1_bet.nii.gz -applyxfm -init vessel2highres.mat -out MRV_CoronalT1.nii.gz');
    %% Segmentation
    disp('Segementing...')
    ImgFile=strcat('/mnt/gallia/chen_lab/analysis/xzhong/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Preprocessed/Sub', num2str(Sub),'/MRV_CoronalT1');
    Command=strcat('singularity exec --bind /rri_disks:/mnt /software/braincharter-vasculature.simg bash /mnt/gallia/chen_lab/analysis/xzhong/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Code/extract_vessels.sh'...
        ,{' '},ImgFile,{' '},'''nii.gz''',' TOF');
    Command=Command{1};
    system(Command);

    cd ..
end


