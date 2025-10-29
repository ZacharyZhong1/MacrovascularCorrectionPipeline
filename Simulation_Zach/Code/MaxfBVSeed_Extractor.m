% Use this MATLAB file to simulate venous signak
% Author: Xiaole Zhong 
% Created at: Sept 30 2020
% Last updated: March 21 2024

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
InputDirGeneral='../../fMRI_Signal_Zach/Preprocessed/';
fBVDirGeneral='../Simulated_Mask/';
OutputDir='../Max_fBV_Seed/';
if ~isdir(OutputDir)
    mkdir(OutputDir)
end
all_files=dir(InputDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

for Sub=20
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
%     InputDir=[InputDirGeneral SubList{Sub}];
    InputDir=[InputDirGeneral 'Sub' num2str(Sub) '/'];
    
    BOLDStruct=MRIread([InputDir 'func_smooth.nii.gz']);
    Height=BOLDStruct.height;
    Width=BOLDStruct.width;
    nSlices=BOLDStruct.depth;
    nFrames=BOLDStruct.nframes;
    BOLDData=BOLDStruct.vol;

    fBVDir=[fBVDirGeneral 'Sub' num2str(Sub) '/'];
    fBVFileName=strcat([fBVDir 'BOLD_VenousfBV.nii.gz']);
    fBVStruct=MRIread(fBVFileName);
    MaskFileName=strcat([fBVDir 'BrainMaskBOLD.nii.gz']);
    MaskStruct=MRIread(MaskFileName);
    fBV=fBVStruct.vol.*logical(MaskStruct.vol);
    max(fBV(:));
    MaxfBVSeed=zeros(1,nFrames);
    CountVoxel=0;
    for h=1:Height
        for w=1:Width
            for s=1:nSlices
                if fBV(h,w,s)==max(fBV(:))
                    TimeCourse=BOLDData(h,w,s,:);
                    TimeCourse=double(reshape(TimeCourse,1,[]));
                    MeanPS=mean(TimeCourse);
                    TimeCourse=TimeCourse-MeanPS;

                    MaxfBVSeed=TimeCourse;
                end
            end
        end
    end
    MaxfBVSeed=MaxfBVSeed-mean(MaxfBVSeed);
    MaxfBVSeed=MaxfBVSeed./max(abs(MaxfBVSeed));
    
    OutputFileName=[OutputDir 'Sub' num2str(Sub) '_MaxfBVSeed.mat'];
    save(OutputFileName,'MaxfBVSeed');
end


