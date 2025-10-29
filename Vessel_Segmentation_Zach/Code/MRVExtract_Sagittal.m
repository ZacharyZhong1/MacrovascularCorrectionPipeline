% Artery Segmentation
% Constructed by Xiaole Zhong
% Last updated: 26 Sept, 2023
clc;
clear;
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio')
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
    AngioFileIn=[InputDir '/anat-angio_acq-sag.nii.gz'];
    AngioFileOut='MRV_Sagittal.nii.gz';
    copyfile(AngioFileIn,AngioFileOut)
    system('gzip MRV_Sagittal.nii.gz');
    %% Skull-stripping
    disp('Extracting brain for T1...')
    InputFileName=[InputDir '/anat-T1w.nii.gz'];
    OutputFileName='T1_bet.nii.gz';
    system(['mri_watershed' ' ' InputFileName ' ' OutputFileName]);
    system(['cp' ' ' InputFileName ' T1.nii.gz']);
%     system('fslroi MRV_Sagittal.nii.gz MRV_Sagittal.nii.gz 0 271 66 271 0 144');
    system('bet2 MRV_Sagittal.nii.gz MRV_Sagittal_ss.nii.gz -m -f 0.7');
%     system('3dSkullStrip -overwrite -mask_vol -input MRV_Sagittal.nii.gz -prefix MRV_Sagittal_ss.nii.gz');
    
    %% Resample to T1 space
    disp('Registration...')
%     system('flirt -in MRV_Sagittal_ss.nii.gz -ref T1_bet.nii.gz -dof 6 -cost corratio -out vessel2highres -omat vessel2highres.mat');
%     system('flirt -in MRV_Sagittal.nii -ref T1_bet.nii.gz -applyxfm -init vessel2highres.mat -out MRV_SagittalT1.nii.gz');
    Temp=MRIread('MRV_Sagittal.nii.gz');
    Temp.vol=flip(Temp.vol,1);
    MRIwrite(Temp,'MRV_Sagittal.nii.gz');
    clear Temp
    system('flirt -in MRV_Sagittal.nii.gz -ref T1.nii.gz -dof 6 -cost normcorr -out vessel2highres -omat vessel2highres.mat');
    system('flirt -in MRV_Sagittal.nii -ref T1.nii.gz -applyxfm -init vessel2highres.mat -out MRV_SagittalT1.nii.gz');
    Temp=MRIread('MRV_SagittalT1.nii.gz');
    Temp.vol=flip(Temp.vol,2);
    MRIwrite(Temp,'MRV_SagittalT1.nii.gz');
    clear Temp
    system('flirt -in MRV_SagittalT1.nii.gz -ref T1.nii.gz -dof 6 -cost normcorr -out vessel2highres -omat vessel2highres.mat');
    system('flirt -in MRV_SagittalT1.nii -ref T1.nii.gz -applyxfm -init vessel2highres.mat -out MRV_SagittalT1.nii.gz');
    
    %% Segmentation
    disp('Segementing...')
    ImgFile=strcat('/mnt/gallia/chen_lab/analysis/xzhong/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Preprocessed/Sub', num2str(Sub),'/MRV_SagittalT1');
    Command=strcat('singularity exec --bind /rri_disks:/mnt /software/braincharter-vasculature.simg bash /mnt/gallia/chen_lab/analysis/xzhong/Calibrated_fMRI_Zach/Vessel_Segementation_Zach/Code/extract_vessels.sh'...
        ,{' '},ImgFile,{' '},'''nii.gz''',' TOF');
    Command=Command{1};
    system(Command);

    cd ..
end

