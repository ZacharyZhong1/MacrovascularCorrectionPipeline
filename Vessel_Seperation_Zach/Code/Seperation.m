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
OutputDirGeneral='../Seperated_Vessels/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(InputDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Create box mask
ArteryBoxH1=[126 130 127 115 123 117 128 136 117 139 135 118 139 129 116 132 124 119 128 127];
ArteryBoxH2=[256 245 243 251 242 259 270 253 233 273 254 241 276 255 230 226 252 254 232 264];
ArteryBoxW1=[34 53 40 44 49 42 57 39 60 47 35 52 43 50 55 38 47 48 49 39];
ArteryBoxW2=[218 208 215 192 203 215 195 212 200 193 224 205 217 209 206 209 207 209 209 216];
ArteryBoxS1=[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
ArteryBoxS2=[208 241 209 213 240 222 202 184 183 177 196 216 201 189 219 169 169 165 173 161];

while block==1
    disp('Block')
end
%% Create folder for raw fMRI data 
for Sub=20
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    
    %% Brain Mask
    InputDir=[InputDirGeneral 'Sub' num2str(Sub)];
    InputFile=[InputDir '/T1_bet.nii.gz'];
    T1_Struct=MRIread(InputFile);
    BrainMask=logical(T1_Struct.vol);
    
    %% Vein Removal
    InputDir=[InputDirGeneral 'Sub' num2str(Sub)];
    InputFile=[InputDir '/MRV_Mask_Enhanced.nii.gz'];
    
    VeinInStruct=MRIread(InputFile);
    VeinOutStruct=VeinInStruct;
    VeinOutStruct.vol(ArteryBoxH1(Sub):ArteryBoxH2(Sub),ArteryBoxW1(Sub):ArteryBoxW2(Sub),ArteryBoxS1(Sub):ArteryBoxS2(Sub))=0;
    VeinOutStruct.vol=VeinOutStruct.vol.*BrainMask;
    
    OutputFileName=[OutputDir '/Venous_Mask.nii.gz'];
    MRIwrite(VeinOutStruct,OutputFileName);
    cd ..
end