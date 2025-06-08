function data_out = prefilter_data(data,trigTimes,prebuffer,postbuffer,basefreq,harmonics,bpfreqs,makenan)
% FILTER_DATA filters only filters during the 
%
% Author: Jeffrey B. Wang
%
% Inputs:
%       data: Original EEG, in the Fieldtrip "raw" format
%       trigTimes: Time (in seconds) for when the artifacts occur
%       buffer: how long (in seconds) to scrub beyond each trigger time
% Output:
%       clean: Fieldtrip structure of the cleaned data

%% Split Trials into artifact + normal

trigTimesStart = trigTimes - prebuffer;
trigTimesEnd = trigTimes + postbuffer;

trigIdxStart = round(trigTimesStart * data.fsample);
trigIdxEnd = round(trigTimesEnd * data.fsample);

trialDef = zeros(2 * length(trigTimes) + 1,3);
trialDef(2:2:end-1,1) = trigIdxStart; % Starting Index
trialDef(1:2:end-2,2) = trigIdxStart; % Ending Index
trialDef(1,1) = 1;

trialDef(3:2:end,1) = trigIdxEnd;
trialDef(2:2:end-1,2) = trigIdxEnd;
trialDef(end,2) = length(data.time{1});

cfg = [];
cfg.trl = trialDef;
data_split = ft_redefinetrial(cfg,data);

%% Apply Filter to data
cfg = [];
cfg.bsfilter       = 'yes';
cfg.bsfiltord      = 3;
line_noise_freqs   = basefreq * (1:harmonics);
cfg.bsfreq         = [line_noise_freqs - 3; line_noise_freqs + 3].'; % use this for NY patients
cfg.bsfreq = [cfg.bsfreq];

% Bandpass filter
cfg.bpfilter       = 'yes';
cfg.bpfiltord      = 3;
cfg.bpfreq       = bpfreqs;
data_notched = ft_preprocessing(cfg,data_split);



%% Now make every other trial NaN (for artifact)
if makenan
    for i = 2:2:length(data_notched.trial) - 1
        data_notched.trial{i}(:) = nan;
    end
end

%% And now merge
data_out = data;
for i = 1:length(data_notched.trial)
    data_out.trial{1}(:,trialDef(i,1):trialDef(i,2)) = data_notched.trial{i};
end