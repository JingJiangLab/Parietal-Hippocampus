function [ftData1, ftData2] = P1_TMS_iEEG_preprocessing(dataDir, saveDir, queue, input_parameters)
% preprocessing of TMS-iEEG data

% Input:
% dataDir: directory of the folder, saving all the raw data of all subjects
% saveDir: directory of the folder, saving all the preprocessed data of all subjects
% queue: a one-column table, including the information of subject, session,
% trigger file, etc.
% input_parameters: parameters for preprocessing; the fields are not
% necessarily complete.

%% default settings
% How much pre and post to exclude from trigger for artifact
preBuffer = 0.01;
postBuffer = 0.025;

% 0 = no-ref; default;
% 1 = bipolar for seeg，common average for SEEG
% when use 1, attention for coordinates as the bipolar re-define the
% location as the middle point of the two adjacents electrodes
% 2 = common average, for SEEG and ECOG seperately
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

ft_defaults

%% update the parameters when there is input
if isfield(input_parameters, 'preBuffer')
    preBuffer = input_parameters.preBuffer;
end
if isfield(input_parameters, 'postBuffer')
    postBuffer = input_parameters.postBuffer;
end
if isfield(input_parameters, 'basefreq')
    basefreq = input_parameters.basefreq;
end
if isfield(input_parameters, 'harmonics')
    harmonics = input_parameters.harmonics;
end
if isfield(input_parameters, 'bpfreqs_narrow')
    bpfreqs_narrow = input_parameters.bpfreqs_narrow;
end
if isfield(input_parameters, 'bpfreqs_broad')
    bpfreqs_broad = input_parameters.bpfreqs_broad;
end
if isfield(input_parameters, 'ref_method')
    ref_method = input_parameters.ref_method;
end
if isfield(input_parameters, 'pre_epoch')
    pre_epoch = input_parameters.pre_epoch;
end
if isfield(input_parameters, 'post_epoch')
    post_epoch = input_parameters.post_epoch;
end
if isfield(input_parameters, 'trigShift')
    trigShift = input_parameters.trigShift;
end

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


total_time = tic;

%% Step 1: load NLX files
% the LFP files should be organized in a folder named "LFP"
% all the empty LFP files should not be in this folder
disp(['------------ Working on: ', queue{1,'Session_Name'}{1}, ' ------------'])
disp('******* 1. Load NLX Files *******')
subparttime = tic;

% Get the Directory of NLX Files
sessionDir = fullfile(dataDir, num2str(queue{1,'Patient'}), 'NLX files', queue{1,'Session_Name'});
files = dir(sessionDir{1});
dirFlags = [files.isdir];
subFolders = files(dirFlags);
sessionDir = fullfile(sessionDir, subFolders(3).name);
lfpDir = fullfile(sessionDir,'LFP');

% Read LFP data
ftData = jw_import_neuralynx(lfpDir);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 2: load Trigger File
disp('******* 2. Load Trigger File *******')
subparttime = tic;

% read Trigger file
sessionDir = fullfile(dataDir, num2str(queue{1,'Patient'}), 'NLX files', queue{1,'Session_Name'});
files = dir(sessionDir{1});
dirFlags = [files.isdir];
subFolders = files(dirFlags);
sessionDir = fullfile(sessionDir, subFolders(3).name);
trigFile = fullfile(sessionDir{1}, queue{1,'TrigFile'}{1});
hdr = ft_read_header(trigFile);
trigInput = ft_read_data(trigFile);

% compute the threshold for identify triggers
mean_thres = (max(trigInput) + min(trigInput))/2;
if mean_thres > 0
    % value > threshold (positive) was idenfitied as trigger
    [trigTimes, trigLengths] = jw_extract_trig_times(trigFile, mean_thres, 0);
else
    % value < threshold (negative) was idenfitied as trigger
    [trigTimes, trigLengths] = jw_extract_trig_times(trigFile, -mean_thres, 1);
end

% exclude the trigger happened within 1 ms
% it is always recommended for a more robust computation
% trigger within 1 ms is not a real trigger but might be artifacts from the machine startup
% it only take place in a few sessions
trigTimes = trigTimes - 0.001;
trigTimes = trigTimes(trigTimes>0);

% compute the inter-trial duration between adjacent triggers
trigDiffs = diff(trigTimes);

% only select those triggers with inter-trial duration > 0.5 s
trigSelect = find(trigDiffs > 0.5);
trigSelect = [1, trigSelect+1];

% the triggers after selection
trigTimes = trigTimes(trigSelect);

% when needed, define trigShift to remove some triggers
trigTimes = trigTimes(trigShift+1:end);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 3: load channel info
disp('******* 3. Load Channel info *******')
subparttime = tic;

channelInfoFName = fullfile(dataDir, num2str(queue{1,'Patient'}), strcat(num2str(queue{1,'Patient'}),'_Contacts.csv'));

% channelInfoFName should save information of all iEEG electrodes
% Variable Channel (instead of Contact) match the LFP filename
channelInfo = readtable(channelInfoFName);
validChannels = strtrim(cellstr(num2str(channelInfo.Channel)));
validChannels = strcat('LFPx',validChannels);

% Now select those channels included in the csv file
cfg = [];
cfg.channel = validChannels;
ftData = ft_selectdata(cfg, ftData);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Save the raw data without any preprocessing
disp('******* Saving Raw data *******')
saveDirSess = fullfile(saveDir, num2str(queue{1,'Patient'}), 'Raw');
mkdir(saveDirSess)

saveFile = fullfile(saveDirSess,strcat(queue{1,'File_Name'}{1},'_Raw.mat'));
saveFailed = true;
attempts = 0;
while saveFailed
    try
        save(saveFile, 'sessionDir', 'ftData', 'trigTimes', 'channelInfo', '-v7.3')
        saveFailed = false;
    catch ME
        saveFailed = true;
        attempts = attempts + 1;
        if attempts < 5
            disp('Save Failed, Attempting Again...')
            pause(5);
        else
            disp('Save Failed, Giving up')
            break
        end
    end
end

%% Step 4: DOWNSAMPLE
disp('******* 4. Downsample *******')
subparttime = tic;

cfg = [];
cfg.resamplefs = 1000;
ftData = ft_resampledata(cfg,ftData);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 5: Remove Channels
% remove those unwarranted channels, e.g., noted as noisy or seizure ...
disp('******* 5. Remove Channels *******')
subparttime = tic;

remove_channels = queue{1, 'Remove_Channels'};
idx_remove = [];

% If only one window to remove, then will be numerical
if isnumeric(remove_channels)
    if ~isnan(remove_channels) % mark
        idx_remove = find(channelInfo{:,'Channel'} == remove_channels);
        channelInfo(idx_remove,:) = [];
    end
else
    % Otherwise need to split by semicolons
    remove_channels= remove_channels{1};
    if ~isempty(remove_channels)
        remove_channels = str2double(split(remove_channels,';'));
        idx_remove = find(ismember(channelInfo{:,'Channel'},remove_channels));
        channelInfo(idx_remove,:) = [];
    end
end

disp(strcat("Removing Channels: ",num2str(idx_remove)));
ftData = reselect_channels(ftData,channelInfo);

channelInfoOrig = channelInfo;

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 6: Re-reference:
subparttime = tic;

% ref_method = 0
% no re-reference
if ref_method == 0
    disp('******* 6. Rereferencing: No Re-Ref *******')
end

% ref_method = 1
% bipolar re-reference for SEEG
% common average re-refernce for ECOG
if ref_method == 1
    disp('******* 6. Rereferencing: BIP for SEEG, CAR for ECOG *******')
    [cortical_labels, bipolar_labelold, bipolar_labelnew, bipolar_tra, channelInfo] = generate_reref_matrix(channelInfoOrig);
    
    % Common Rereference for Corticals ECOG
    cfg = [];
    cfg.channel = cortical_labels;
    reref_cortical = ft_selectdata(cfg, ftData);
    
    if ~isempty(cortical_labels)
        cfg = [];
        cfg.reref       = 'yes';
        cfg.refchannel  = 'all';
        cfg.refmethod   = 'avg';
        
        reref_cortical = ft_preprocessing(cfg, reref_cortical);
    end
    
    % Bipolar Montage for Depths SEEG
    cfg = [];
    cfg.channel = bipolar_labelold;
    reref_depth = ft_selectdata(cfg, ftData);
    
    if ~isempty(bipolar_labelold)
        cfg = [];
        cfg.channel = bipolar_labelold;
        cfg.montage = [];
        cfg.montage.tra = bipolar_tra;
        cfg.montage.labelold = bipolar_labelold;
        cfg.montage.labelnew = bipolar_labelnew;
        reref_depth = ft_preprocessing(cfg, reref_depth);
    end
    
    % Now append the Cortical and Depth Electrodes
    cfg = [];
    ftData = ft_appenddata(cfg, reref_cortical, reref_depth);
end

% ref_method = 2
% common average re-refernce for ECOG and SEEG, seperately
if ref_method == 2
    disp('******* 6. Rereferencing: CAR for SEEG/ECOG seperately *******');
    [cortical_labels, bipolar_labelold, bipolar_labelnew, bipolar_tra, channelInfo] = generate_reref_matrix(channelInfoOrig);
    
    % Common Rereference for Corticals ECOG
    cfg = [];
    cfg.channel = cortical_labels;
    reref_cortical = ft_selectdata(cfg, ftData);
    
    if ~isempty(cortical_labels)
        cfg = [];
        cfg.reref       = 'yes';
        cfg.refchannel  = 'all';
        cfg.refmethod   = 'avg';
        
        reref_cortical = ft_preprocessing(cfg, reref_cortical);
    end
    
    % Common Rereference for Depths SEEG
    cfg = [];
    cfg.channel = bipolar_labelold;
    reref_depth = ft_selectdata(cfg, ftData);
    
    if ~isempty(bipolar_labelold)
        cfg = [];
        cfg.reref       = 'yes';
        cfg.refchannel  = 'all';
        cfg.refmethod   = 'avg';
        
        reref_depth = ft_preprocessing(cfg, reref_depth);
    end
    % Now append the Cortical and Depth Electrodes
    cfg = [];
    ftData = ft_appenddata(cfg, reref_cortical, reref_depth);
end

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 7: FILTERING
% filtering was done for artifact duration and normal duration seperately
disp('******* 7. Filtering *******')
subparttime = tic;

% Narrow band filtering: 2-35 Hz
ftData1 = prefilter_data(ftData,trigTimes,preBuffer,postBuffer,basefreq,harmonics,bpfreqs_narrow,false);
% Broad band filtering: 2-200 Hz
ftData2 = prefilter_data(ftData,trigTimes,preBuffer,postBuffer,basefreq,harmonics,bpfreqs_broad,false);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 8: INTERPOLATION
% filtering was done for artifact duration and normal duration seperately
disp('******* 8. Interpolation *******')
% do interpolation after filtering
ftData1 = dh_cleanartifact_interp(ftData1,trigTimes, preBuffer, postBuffer,1);
ftData2 = dh_cleanartifact_interp(ftData2,trigTimes, preBuffer, postBuffer,1);


% %% Step 8: DOWNSAMPLE
% disp('******* 8. Downsample *******')
% subparttime = tic;
% 
% cfg = [];
% cfg.resamplefs = 1000;
% ftData = ft_resampledata(cfg,ftData);
% ftData1 = ft_resampledata(cfg,ftData1);
% ftData2 = ft_resampledata(cfg,ftData2);
% 
% subparttime = toc(subparttime) / 60;
% disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% Step 9: EPOCH DATA
disp('******* 9. Epoch Data *******')
subparttime = tic;

trigIdx = round(trigTimes * ftData.fsample);
trialDef = zeros(length(trigIdx),3);
trialDef(:,1) = round(trigIdx - ftData.fsample * pre_epoch); % Starting Index of Epoch
trialDef(:,2) = round(trigIdx + ftData.fsample * post_epoch); % Ending Index
trialDef(:,3) = -round(ftData.fsample * pre_epoch); % How far past the trigger the start of the epoch is (hence negative for starting before trigger)

cfg = [];
cfg.trl = trialDef;
ftData1 = ft_redefinetrial(cfg,ftData1);
ftData2 = ft_redefinetrial(cfg,ftData2);

subparttime = toc(subparttime) / 60;
disp(strcat(num2str(subparttime), ' minutes have elapsed'))


%% SAVE EPOCHED RESULTS
saveDirSess = fullfile(saveDir, num2str(queue{1,'Patient'}), 'Epoched');
mkdir(saveDirSess)

% save results by narrow bandpass filter
ftData = ftData1;
saveFile = fullfile(saveDirSess,strcat(queue{1,'File_Name'}{1},'_NarrowFilter_refMethod',num2str(ref_method), '.mat'));
saveFailed = true;
attempts = 0;
while saveFailed
    try
        save(saveFile, 'sessionDir', 'ftData', 'trigTimes', 'channelInfo', 'parameters', '-v7.3')
        saveFailed = false;
    catch ME
        saveFailed = true;
        attempts = attempts + 1;
        if attempts < 5
            disp('Save Failed, Attempting Again...')
            pause(5);
        else
            disp('Save Failed, Giving up')
            break
        end
    end
end

% save results by broad bandpass filter
ftData = ftData2;
saveFile = fullfile(saveDirSess,strcat(queue{1,'File_Name'}{1},'_BroadFilter_refMethod',num2str(ref_method), '.mat'));
saveFailed = true;
attempts = 0;
while saveFailed
    try
        save(saveFile, 'sessionDir', 'ftData', 'trigTimes', 'channelInfo', 'parameters', '-v7.3')
        saveFailed = false;
    catch ME
        saveFailed = true;
        attempts = attempts + 1;
        if attempts < 5
            disp('Save Failed, Attempting Again...')
            pause(5);
        else
            disp('Save Failed, Giving up')
            break
        end
    end
end

total_time = toc(total_time) / 60;
disp(['------------ Finish ', queue{1,'Session_Name'}{1}, ' in ',num2str(total_time), ' minutes ------------'])

end

