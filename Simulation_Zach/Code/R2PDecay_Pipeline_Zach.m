% Upsample the vascular mask and brain mask and then allign high-res space
% with BOLD space and downsample brian mask
% Author: Xiaole Zhong 
% Created at: April 1 2024
% Last updated: April 1 2024

clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio');
B0DirGeneral='../SimulatedB0Map_Yv/';
OutputDirGeneral='../Simulated_Signal/R2P_Yv/';
InfoDirGeneral='../Simulated_Mask/';
SignalDir='../Yv/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(B0DirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Sequency Parameter
TR=4500;        % Repetition Time (ms)
TE=30;          % Echo Time (ms)   
alpha=pi/2;       % Flip angle for GRE (deg)
B0=3;           % Main magnetic file (Tesla)
gamma=267.52e3;   % gyromagnetic ratio (rad/T/ms)

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
    
    for Time=1:NumTime
        disp(strcat('Time:',num2str(Time)))
        disp('Inputing and turncating B0 Map...')
        
        B0Dir=[B0DirGeneral 'Sub' num2str(Sub)];
        FileIn=[B0Dir '/VenousB0MapIteration_',num2str(1),'Frame_',num2str(Time),'.nii.gz'];
        B0MapStruct=MRIread(FileIn);
        B0Map=B0MapStruct.vol;
        B0Map=B0Map(PaddingT1New(3)+1:PaddingT1New(4)+4,...
            PaddingT1New(1)+1:PaddingT1New(2)+4,...
            PaddingT1New(5)+1:PaddingT1New(6)+4);
        
        BOLDBrainMaskStruct=MRIread([InfoDir '/mask_BOLD_autobox.nii.gz']);
        BOLDBrainMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
        BOLDVenousMask=zeros(BOLDBrainMaskStruct.height,BOLDBrainMaskStruct.width,BOLDBrainMaskStruct.depth);
        Height=BOLDBrainMaskStruct.height;
        Width=BOLDBrainMaskStruct.width;
        nSlices=BOLDBrainMaskStruct.depth;
        %% Dephase
        disp('Computing B0 map...')
        dPhi=(gamma.*B0Map.*TE);
        Mxy=exp(i*dPhi);
        clear dPhi
        
        for h=1:Height
            for w=1:Width
                for s=1:nSlices
                    SubMxyMap=Mxy((h-1)*20+1:(h-1)*20+20,(w-1)*20+1:(w-1)*20+20,(s-1)*25+1:(s-1)*25+25);
                    DecaySignal(h,w,s)=abs(mean(SubMxyMap(:)));
                end
            end
        end
        
        disp('Outputing BOLD space data...')
        OutputFile=MRIread([InfoDir '/BrainMaskBOLD.nii.gz']);
        OutputFile.vol=zeros(OutputFile.height,OutputFile.width,OutputFile.depth);
        OutputFile.vol(PaddingBOLD(3)+1:PaddingBOLD(4)+1,PaddingBOLD(1)+1:PaddingBOLD(2)+1,PaddingBOLD(5)+1:PaddingBOLD(6)+1)...
            =DecaySignal;
        MRIwrite(OutputFile,[OutputDir '/R2PIteration_',num2str(1),'Frame_',num2str(Time),'.nii.gz']);
        clear DecaySignal
    end
end