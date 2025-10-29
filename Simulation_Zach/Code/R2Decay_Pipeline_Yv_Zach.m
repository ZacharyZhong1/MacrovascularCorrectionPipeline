% Simulate R2 related signal
% Author: Xiaole Zhong 
% Created at: April 1 2024
% Last updated: 29 Oct 2025

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
OutputDirGeneral='../Simulated_Signal/R2_Yv/';
InfoDirGeneral='../Simulated_Mask/';
SignalDir='../Yv/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(InfoDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Sequency Parameter
Yvein=0.6;      % 60% oxygenation for vein
TE=30;          % Echo Time (ms) 
TR=4500;        % Reptition Time (ms) 
gamma=267.52e3;   % gyromagnetic ratio (rad/T/ms)
alpha=pi/2;       % Flip angle for GRE (deg)
DownFactor=20;      % Downsampling factor (Voxel size=DownFactor*B0Map resolution)
UpsampleFactor=2; % Upsample vessel to 0.2mm reso
T1Tissue=1465;    % T1 of brain (ms)
T1Blood=1650;    % T1 of blood (ms)
B0=3;
R2Tissue=(1.74*B0+7.77)/1000; 

for Sub=1:NumSub
    disp(['Subject:' num2str(Sub) '/Total Subjects:' num2str(NumSub)])
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end
    
    SignalFileName=[SignalDir 'Sub' num2str(Sub) '_Yv.mat'];
    load(SignalFileName);
    NumTime=length(Yv);
    
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
    
    YveinTC=Yvein+Yvein*0.30*Yv;   % Oxygenated level variation
    R2Blood=(12.67*B0^2*(1-YveinTC).^2+2.74*B0-0.6)/1000;

    
    disp('Outputing BOLD space data...')
    for Time=1:NumTime 
        
        BloodSignal=exp(-R2Blood(Time)*TE);
        BrainSignal=exp(-R2Tissue*TE);
        
        for h=1:Height
            for w=1:Width
                for s=1:nSlices
                    SubBrainMask=BrainMask((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                    SubVenousMask=VenousMask((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                    VoxelSize=25*20*20;
                    VesselVolume=sum(sum(sum(SubVenousMask)));
                    BrainVolume=VoxelSize-VesselVolume;
                    DecaySignal(h,w,s)=VesselVolume/VoxelSize*BloodSignal...
                        +BrainVolume/VoxelSize*BrainSignal;
                end
            end
        end
        
        OutputFile=MRIread([InfoDir '/BrainMaskBOLD.nii.gz']);
        OutputFile.vol=zeros(OutputFile.height,OutputFile.width,OutputFile.depth);
        OutputFile.vol(PaddingBOLD(3)+1:PaddingBOLD(4)+1,PaddingBOLD(1)+1:PaddingBOLD(2)+1,PaddingBOLD(5)+1:PaddingBOLD(6)+1)...
            =DecaySignal;
        MRIwrite(OutputFile,[OutputDir '/R2Iteration_',num2str(1),'Frame_',num2str(Time),'.nii.gz']);
        clear DecaySignal
    end
end
