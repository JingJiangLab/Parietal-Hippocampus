function [ftData_epoch_tms, ftData_epoch_sham] = P2_Detrend(queue, ref_method, saveDir, input_parameters)
% preprocessing of TMS-iEEG data

% Input
% queue: a one-column table, including the information of subject, session,
% trigger file, etc.
% saveDir: directory of the folder, saving the processed data before and after detrending
% input_parameters: parameters for preprocessing; the fields are not
% necessarily complete.

% Output
% ftData_epoch_tms/ftData_epoch_sham: detrended data
% all the detrended data were saved

%% default settings
% de_time: time window for detrend
de_time = [0.025, 0.5];
% loadDir =  '/Volumes/Vincent_01/postdoc/preprocess';
% saveDir = '/Users/zli328/Documents/Research/Research/Project_Hippocampus/preprocess/Comparisons_TMS_sham_allSites';

% if lift the data after detrend
% detrend might make the data discontinuous at the onset and offset
% if_Lift = 1, default; lift the data at the detrend offset
% if_Lift = 0; do not lift the data
if_Lift = 0;

de_method = 1;


%% update the parameters when there is input
if isfield(input_parameters, 'de_time')
    de_time = input_parameters.de_time;
end
if isfield(input_parameters, 'if_Lift')
    if_Lift = input_parameters.if_Lift;
end
if isfield(input_parameters, 'de_method')
    de_method = input_parameters.de_method;
end

de_parameters = [];
de_parameters.de_time = de_time;
de_parameters.if_Shift = if_Lift;
de_parameters.de_method = de_method;


disp(['------------ Working on: ', num2str(queue{1,'Patient'}), ' ------------'])


%% do detrend for both two versions of results
% narrow filter: default 2-35 Hz
% broad filter: default 2-200 Hz

for filter_i = 1:2
    
    %% load data
    loadDirSess = fullfile(saveDir, num2str(queue{1,'Patient'}), 'Epoched');
    
    % results by narrow bandpass filter
    if filter_i == 1
        TMSFile = fullfile(loadDirSess,strcat(queue{1,'TMS_File_Name'}{1},'_NarrowFilter_refMethod',num2str(ref_method), '.mat'));
        ShamFile = fullfile(loadDirSess,strcat(queue{1,'Sham_File_Name'}{1},'_NarrowFilter_refMethod',num2str(ref_method), '.mat'));
    end
    % results by broad bandpass filter
    if filter_i == 2
        TMSFile = fullfile(loadDirSess,strcat(queue{1,'TMS_File_Name'}{1},'_BroadFilter_refMethod',num2str(ref_method), '.mat'));
        ShamFile = fullfile(loadDirSess,strcat(queue{1,'Sham_File_Name'}{1},'_BroadFilter_refMethod',num2str(ref_method), '.mat'));
    end
    
    load(TMSFile);
    ftData_epoch_tms = ftData;
    load(ShamFile);
    ftData_epoch_sham = ftData;
    
    disp('**** File Load Complete  ****')
    
    %% Timelock Analysis
    cfg = [];
    %     close all
    channel_names = cellfun(@(x) sscanf(x,'LFPx%f'),ftData.label);
    [~,sorted_idx] = sortrows(channel_names);
    
    ftData_timelocked_tms = ft_timelockanalysis(cfg, ftData_epoch_tms);
    ftData_timelocked_sham = ft_timelockanalysis(cfg, ftData_epoch_sham);
    
    
    %% do detrend
    subparttime = tic;
    if de_method == 0
        disp(['**** No Detrending ****'])
    else
        % Limit fit to 25 to 500 ms post trigger
        mask = (ftData_epoch_tms.time{1} >= de_time(1)) & (ftData_epoch_tms.time{1} < de_time(2));
        mask_before = ftData_epoch_tms.time{1} < de_time(1);
        mask_after = ftData_epoch_tms.time{1} >= de_time(2);
        time_fit = ftData_epoch_tms.time{1}(mask);
        
        expFun = @(a,t) a(1) * exp(-abs(a(2)) * (t-a(5))) + a(3) * exp(-abs(a(4)) * (t-a(5)));
        start_fit = [200,14,200,10,0.03];
        parfevalOnAll(gcp(), @warning, 0, 'off');
        
        tms_names = {'TMS','Sham'};
        for tms_i = 1:2
            disp(['**** Detrending ', tms_names{1,tms_i}, ' Condition ****'])
            
            if tms_i == 1
                trial_data = ftData_epoch_tms.trial;
                ftData_timelocked_tms.var(ftData_timelocked_tms.var == 0) = 1;
                all_weights = 1 ./ ftData_timelocked_tms.var;
                N_channels = length(ftData_epoch_tms.label);
                mask_after = ftData_epoch_tms.time{1} >= de_time(2);
            else
                trial_data = ftData_epoch_sham.trial;
                ftData_timelocked_sham.var(ftData_timelocked_sham.var == 0) = 1;
                all_weights = 1 ./ ftData_timelocked_sham.var;
                N_channels = length(ftData_epoch_sham.label);
                mask_after = ftData_epoch_sham.time{1} >= de_time(2);
            end
            
            parfor tr = 1:length(trial_data)
                for ch = 1:N_channels
                    
                    if de_method == 1
                        weights = all_weights(ch,mask); % Compute weights as inverse of variance
                        model_linear = fit(time_fit.',trial_data{tr}(ch,mask).','poly1','Weights',weights);
                        try
                            model_exp = fitnlm(time_fit.',trial_data{tr}(ch,mask).',expFun,start_fit,'Weight',weights);
                        catch exception
                            model_exp = [];
                        end
                        
                        % Calculate Akaike Information Criterion (AIC)
                        linear_aic = length(time_fit) * log(sum((model_linear(time_fit).' - trial_data{tr}(ch,mask)).^2 .* weights)) ...
                            + 2;
                        if isempty(model_exp)
                            exp_aic = Inf;
                        else
                            exp_aic = length(time_fit) * log(sum((model_exp.feval(time_fit) - trial_data{tr}(ch,mask)).^2 .* weights)) ...
                                + 2;
                        end
                        
                        if linear_aic < exp_aic
                            trial_data{tr}(ch,mask) = trial_data{tr}(ch,mask) - model_linear(time_fit).';
                            if if_Lift == 1
                                % shift the data after the duration for detrending
                                temp_data = model_linear(time_fit).';
                                trial_data{tr}(ch,mask_after) = trial_data{tr}(ch,mask_after) - temp_data(end);
                            end
                        else
                            trial_data{tr}(ch,mask) = trial_data{tr}(ch,mask) - model_exp.feval(time_fit);
                            if if_Lift == 1
                                % shift the data after the duration for detrending
                                temp_data = model_exp.feval(time_fit);
                                trial_data{tr}(ch,mask_after) = trial_data{tr}(ch,mask_after) - temp_data(end);
                            end
                        end
                    end
                end
            end
            
            if tms_i == 1
                ftData_epoch_tms_de = ftData_epoch_tms;
                ftData_epoch_tms_de.trial = trial_data;
            else
                ftData_epoch_sham_de = ftData_epoch_sham;
                ftData_epoch_sham_de.trial = trial_data;
            end
        end
        
        
        %% re-do interpolation for the artifacts duration after detrend
        disp('**** Re-do Interpolation ****')
        preBuffer = parameters.preBuffer;
        postBuffer = de_time(1);
        fs = ftData_epoch_tms_de.fsample;
        pre_pos = round((1 - preBuffer) * fs);
        post_pos = round((1 + postBuffer) * fs);
        
        % do interpolation
        cfgi = [];
        cfgi.useSIGNI = 1;   % 1 = use SIGNI method; 0 = use other method
        cfgi.artfctdef.reject = 'nan';
        cfgi.artfctdef.feedback = 'no';
        
        % cfgi.method/prewindow/postwindow: specific method, window before and after segment to use data points for interpolation
        % These inputs are not in use when cfgi.useSIGNI = 1
        cfgi.method = 'pchip';
        cfgi.prewindow = 0.01;
        cfgi.postwindow = 0.01;
        
        n_trials = size(ftData_epoch_tms.trial,2);
        ftData_epoch_tms_de_nan = ftData_epoch_tms_de;
        for trial_i = 1:n_trials
            ftData_epoch_tms_de_nan.trial{1,trial_i}(:, pre_pos:post_pos) = nan;
        end
        ftData_epoch_tms_de_inter = dh_interpolatenan(cfgi, ftData_epoch_tms_de_nan); % interpolate nan value
        ftData_epoch_tms = ftData_epoch_tms_de_inter;
        
        n_trials = size(ftData_epoch_sham.trial,2);
        ftData_epoch_sham_de_nan = ftData_epoch_sham_de;
        for trial_i = 1:n_trials
            ftData_epoch_sham_de_nan.trial{1,trial_i}(:,pre_pos:post_pos) = nan;
        end
        ftData_epoch_sham_de_inter = dh_interpolatenan(cfgi, ftData_epoch_sham_de_nan); % interpolate nan value
        ftData_epoch_sham = ftData_epoch_sham_de_inter;
    end
    
    subparttime = toc(subparttime) / 60;
    disp(strcat(num2str(subparttime), ' minutes have elapsed'))

    %%
    disp('**** Saving Detrended Data ****')
    
    saveDirSess = fullfile(saveDir, num2str(queue{1,'Patient'}), 'Detrended');
    mkdir(saveDirSess);
    % results by narrow bandpass filter
    if filter_i == 1
        saveFile = fullfile(saveDirSess,strcat(queue{1,'Save_File_Name'}{1},'_NarrowFilter_refMethod',num2str(ref_method), '.mat'));
    end
    % results by broad bandpass filter
    if filter_i == 2
        saveFile = fullfile(saveDirSess,strcat(queue{1,'Save_File_Name'}{1},'_BroadFilter_refMethod',num2str(ref_method), '.mat'));
    end
    
    if de_method == 0
        saveFile = [saveFile(1:end-4), '_NoDe.mat'];
    else
        saveFile = [saveFile(1:end-4), '_De.mat'];
    end
    
    save(saveFile, 'ftData_epoch_tms', 'ftData_epoch_sham', 'ftData_timelocked_tms', 'ftData_timelocked_sham', 'channelInfo', 'de_parameters', 'parameters', '-v7.3')
    
end
end
