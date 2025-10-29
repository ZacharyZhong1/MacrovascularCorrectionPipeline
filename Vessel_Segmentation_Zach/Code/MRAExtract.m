% Artery Segmentation
% Constructed by Xiaole Zhong
% Last updated: 26 Sept, 2023
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
for Sub=3:NumSub
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    
    InputDir=[InputDirGeneral SubList{Sub}];
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub+1)];
    
    if ~isdir(OutputDir)
        mkdir(OutputDir)
    end
    cd(OutputDir);
    %% Copy TOF From Raw Data Folder
%     AngioFileIn=[InputDir '/6_anat-angio_acq-Ax-Asc.nii'];
    AngioFileIn=[InputDir '/00_MRV_Summed.nii.gz'];
    AngioFileOut='MRA.nii.gz';
    copyfile(AngioFileIn,AngioFileOut)

    %% Skull-stripping
    disp('Extracting brain for T1...')
    InputFileName=[InputDir '/5_anat-T1w.nii'];
    OutputFileName='T1_bet.nii.gz';
    system(['mri_watershed' ' ' InputFileName ' ' OutputFileName]);
    system('bet2 MRA.nii.gz MRA_ss.nii.gz -m -f 0.2');
    
    %% Resample to T1 space
    disp('Registration...')
%     system('flirt -in MRA_ss.nii.gz -ref T1_bet.nii.gz -dof 6 -cost corratio -out vessel2highres -omat vessel2highres.mat');
%     system('flirt -in MRA.nii -ref T1_bet.nii.gz -applyxfm -init vessel2highres.mat -out MRAT1.nii.gz');

    %% Segmentation
    disp('Segementing...')
    ImgFile=strcat('/mnt/maja/chen_lab/analysis/xzhong/CalibratedFMRI/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Preprocessed/Sub', num2str(Sub+1),'/MRA');
    Command=strcat('singularity exec --bind /rri_disks:/mnt /software/braincharter-vasculature.simg bash /mnt/maja/chen_lab/analysis/xzhong/CalibratedFMRI/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Code/extract_vessels.sh'...
        ,{' '},ImgFile,{' '},'''nii.gz''',' TOF');
    Command=Command{1};
    system(Command);
    cd /home2/xzhong
    delete *.nii.gz
    cd '/rri_disks/maja/chen_lab/analysis/xzhong/CalibratedFMRI/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Preprocessed'

    cd ..
end

