% preprocessing for TMS-iEEG
% including four parts:
% Part 1: Basic preprocessing
% Part 2: Split sessions [optional]
% Part 3: Detrend

% To do:
% use more specific names;
% add plot: plot them together or seperate figures, with example channels;


%% -------------------------------------------------
%% Part 1: Basic preprocessing
%% -------------------------------------------------

clear
clc
close all

% 1_Process_Queue_tms.xlsx
% Load the information of all sessions for preprocessing, includes:
% Patient: subject index
% Session_name
% File_name: for saving data
% TrigFile: checked by P0_FindTrigger and filled manually

queueFName = fullfile(pwd, 'queue_files/1_Process_Queue_tms.xlsx');
queue = readtable(queueFName);

% the directory of raw data
dataDir =  fullfile(pwd, 'Raw_data');
% the directory for saving preprocessed data
saveDir =  fullfile(pwd, 'Preprocessed_data');

%% Parameters for preprocessing
% How much pre and post to exclude from trigger for artifact
preBuffer = 0.01;
postBuffer = 0.025;

% 0 = no-ref; default;
% 1 = bipolar re-reference for seeg，common average for SEEG
% when use 1, attention for coordinates as the bipolar re-define the
% location as the middle point of the two adjacents electrodes
% 2 = common average re-reference , for SEEG and ECOG seperately
ref_method = 0;

% Base Frequency for Line Noise
basefreq = 60;
% How many harmonics of line noise to include in bandstop
harmonics = 7;

% frequency bands for narrow and broad band filtering
bpfreqs_narrow = [2,35];
bpfreqs_broad = [2,200];

% How much pre and post TMS for data epoch
pre_epoch = 1.0; % Length to integrate beforehand
post_epoch = 2.0; % Length of epoch in seconds

% remove some triggers when needed
trigShift = 0; 

% all parameters were saved in a structure, as an input for P1_TMS_iEEG_preprocessing
parameters = [];
parameters.preBuffer = preBuffer;
parameters.postBuffer = postBuffer;
parameters.basefreq = basefreq;
parameters.harmonics = harmonics;
parameters.bpfreqs_narrow = bpfreqs_narrow;
parameters.bpfreqs_broad = bpfreqs_broad;
parameters.ref_method = ref_method;
parameters.pre_epoch = pre_epoch;
parameters.post_epoch = post_epoch;
parameters.trigShift = trigShift;


%% Do basic preprocessing
% preprocessed data were saved
queue_num = size(queue, 1);
for queue_i = 1:2
    P1_TMS_iEEG_preprocessing(dataDir, saveDir, queue(queue_i,:), parameters);
end

%% -------------------------------------------------
%% Part 2: Detrend
%% -------------------------------------------------
% decay removal
% should prepare and match the TMS and Sham first, each saved as a seperate file
% after detrend, TMS and Sham was saved in the same file

queueFName = fullfile(pwd, 'queue_files/2_Detrend_Queue_tms.xlsx');
queue = readtable(queueFName);

% the directory of saved files
saveDir =  fullfile(pwd, 'Preprocessed_data');

% 0 = no-ref; default;
% 1 = bipolar re-reference for seeg，common average for SEEG
% when use 1, attention for coordinates as the bipolar re-define the
% location as the middle point of the two adjacents electrodes
% 2 = common average re-reference , for SEEG and ECOG seperately
% should remain the same as the Part 1
ref_method = 0;

% 0 = no detrend;
% 1 = do detrend, compare linear and exp
de_method = 1;
% de_time: time window for detrend
de_time = [0.025, 0.5];

% if lift the data after detrend
% detrend might make the data discontinuous at the onset and offset
% if_Lift = 1, default; lift the data at the detrend offset
% if_Lift = 0; do not lift the data
if_Lift = 0;


% all parameters were saved in a structure, as an input for P1_TMS_iEEG_preprocessing
de_parameters = [];
de_parameters.de_method = de_method;
de_parameters.de_time = de_time;
de_parameters.if_Shift = if_Lift;

queue_num = size(queue, 1);
for queue_i = 1:queue_num
    P2_Detrend(queue(queue_i,:), ref_method, saveDir, de_parameters);
end

