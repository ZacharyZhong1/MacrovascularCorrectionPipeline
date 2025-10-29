% Regress out the macrovascular effect based on both simulation and Yv
% signal.
% Perform func_bet for functional connectivity and func_smooth for SD
% ROI defined by 1% max(sim_BOLD)
% Constructed by Xiaole Zhong
% Last updated: May 18, 2024
clc;
clear;

%% I/O information
addpath('/rri_disks/atalante/chen_lab/analysis/XzhongVascular/MRIio')
InVivoDataDirGeneral='../../fMRI_Signal_Zach/Preprocessed/';
SimBOLDDir='../../Simulation_Zach/Simulated_Signal/BOLDSignal/';
YvDataDir='../../Simulation_Zach/Yv/';
OutputDirGeneral='../CorrectedBOLD/';
if ~isdir(OutputDirGeneral)
    mkdir(OutputDirGeneral)
end
all_files=dir(InVivoDataDirGeneral);
all_dir=all_files([all_files(:).isdir]);
NumSub=numel(all_dir)-2;

%% Correction Loop
for Sub=1:NumSub
    disp(['Sub:' num2str(Sub)])
    OutputDir=[OutputDirGeneral 'Sub' num2str(Sub)];
    if ~isdir( OutputDir)
        mkdir( OutputDir)
    end

    % Input Simulated Data
    disp('Importing Simulated Data...')
    SimBOLDFileName=[SimBOLDDir 'Sub' num2str(Sub) '_BOLDSignal_Yv.nii.gz'];
    SimBOLDStruct=MRIread(SimBOLDFileName);
    SimBOLD=SimBOLDStruct.vol;
    YvFileName=[YvDataDir 'Sub' num2str(Sub) '_Yv.mat'];
    load(YvFileName);
    Yv=Yv-mean(Yv);
    
    % Compute ROI
    disp('Computing ROI...')
    SimRSFA=std(SimBOLD,[],4)./mean(SimBOLD,4);
    Mask=logical(SimRSFA>=0.01*max(SimRSFA(:)));
    disp(['ROI Size:' num2str(sum(Mask(:)))])

    % Input In-Vivo Data
    disp('Importing InVivoData (for RSFA)...')
    InVivoDataDir=[InVivoDataDirGeneral 'Sub' num2str(Sub) '/'];
    InVivoBOLDFileName=[InVivoDataDir 'func_smooth.nii.gz'];
    InVivoBOLDStruct=MRIread(InVivoBOLDFileName);
    InVivoBOLD=InVivoBOLDStruct.vol;
    Height=InVivoBOLDStruct.height;
    Width=InVivoBOLDStruct.width;
    nSlices=InVivoBOLDStruct.depth;

    BrainMaskFileName=[InVivoDataDir 'mask.nii.gz'];
    BrainMaskStruct=MRIread(BrainMaskFileName);
    BrainMask=BrainMaskStruct.vol;
    Mask=double(Mask).*double(BrainMask);

    OutputStruct_Sim=InVivoBOLDStruct;
    OutputStruct_Yv=InVivoBOLDStruct;

    disp('Regressing InVivoData (for RSFA)...')
    for h=1:Height
        for w=1:Width
            for s=1:nSlices
                if Mask(h,w,s)~=0
                    Signal=reshape(InVivoBOLD(h,w,s,:),1,[]);
                    Signal=Signal-mean(Signal);
                    SimSignal=reshape(SimBOLD(h,w,s,:),1,[]);
                    SimSignal=SimSignal-mean(SimSignal);

                    % Cross-correlation to ensure synchronize (Sim)
                    [CCC,lag]=xcorr(Signal,SimSignal,'coeff');
                    ShiftLag=lag(find(CCC==max(CCC)));
                    SimSignal_Shift=circshift(SimSignal,ShiftLag);
                   
                    % Regressim (Sim)
                    X=[ones(1,47); SimSignal_Shift];

                    b=regress(Signal',X');
                    y=b(1)+b(2).*SimSignal_Shift;
        
                    OutputStruct_Sim.vol(h,w,s,:)=Signal-y;

                    % Cross-correlation to ensure synchronize (Yv)
                    [CCC,lag]=xcorr(Signal,Yv,'coeff');
                    ShiftLag=lag(find(CCC==max(CCC)));
                    Yv_Shift=circshift(Yv,ShiftLag);
                   
                    % Regressim (Yv)
                    X=[ones(1,47); Yv_Shift];

                    b=regress(Signal',X');
                    y=b(1)+b(2).*Yv_Shift;
        
                    OutputStruct_Yv.vol(h,w,s,:)=Signal-y;                   
                end
            end
        end
    end
    
    % Output corrected cata
    disp('Outputing InVivoData (for RSFA)...')
    OutputFileName=[OutputDir '/func_smooth_Sim.nii.gz'];
    MRIwrite(OutputStruct_Sim, OutputFileName);
    OutputFileName=[OutputDir '/func_smooth_Yv.nii.gz'];
    MRIwrite(OutputStruct_Yv, OutputFileName);

    % Input Simulated Data
    disp('Importing InVivoData (for FC)...')
    InVivoDataDir=[InVivoDataDirGeneral 'Sub' num2str(Sub) '/'];
    InVivoBOLDFileName=[InVivoDataDir 'func.nii.gz'];
    InVivoBOLDStruct=MRIread(InVivoBOLDFileName);
    InVivoBOLD=InVivoBOLDStruct.vol;
    Height=InVivoBOLDStruct.height;
    Width=InVivoBOLDStruct.width;
    nSlices=InVivoBOLDStruct.depth;

    OutputStruct_Sim=InVivoBOLDStruct;
    OutputStruct_Yv=InVivoBOLDStruct;

    disp('Regressing InVivoData (for FC)...')
    for h=1:Height
        for w=1:Width
            for s=1:nSlices
                if Mask(h,w,s)~=0
                    Signal=reshape(InVivoBOLD(h,w,s,:),1,[]);
                    MeanSignal=mean(Signal);
                    Signal=double(Signal-mean(Signal));
                    SimSignal=reshape(SimBOLD(h,w,s,:),1,[]);
                    SimSignal=SimSignal-mean(SimSignal);

                    % Cross-correlation to ensure synchronize (Sim)
                    [CCC,lag]=xcorr(Signal,SimSignal,'coeff');
                    ShiftLag=lag(find(CCC==max(CCC)));
                    SimSignal_Shift=circshift(SimSignal,ShiftLag);
                   
                    % Regressim (Sim)
                    X=[ones(1,47); SimSignal_Shift];

                    b=regress(Signal',X');
                    y=b(1)+b(2).*SimSignal_Shift;
        
                    OutputStruct_Sim.vol(h,w,s,:)=Signal-y+MeanSignal;

                    % Cross-correlation to ensure synchronize (Yv)
                    [CCC,lag]=xcorr(Signal,Yv,'coeff');
                    ShiftLag=lag(find(CCC==max(CCC)));
                    Yv_Shift=circshift(Yv,ShiftLag);
                   
                    % Regressim (Yv)
                    X=[ones(1,47); Yv_Shift];

                    b=regress(Signal',X');
                    y=b(1)+b(2).*Yv_Shift;
        
                    OutputStruct_Yv.vol(h,w,s,:)=Signal-y+MeanSignal;                   
                end
            end
        end
    end
    
    % Output corrected cata
    disp('Outputing InVivoData (for FC)...')
    OutputFileName=[OutputDir '/func_Sim.nii.gz'];
    MRIwrite(OutputStruct_Sim, OutputFileName);
    OutputFileName=[OutputDir '/func_Yv.nii.gz'];
    MRIwrite(OutputStruct_Yv, OutputFileName);
end

