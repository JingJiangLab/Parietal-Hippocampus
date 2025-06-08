function ftdata = jw_import_neuralynx(sessionDir, varargin)
% JW_IMPORT_NEURALYNX imports a set of Neuralynx continuous channel files
% (ncs) and imports them into a fieldtrip structure after preprocessing.
%
% Author: Jeffrey B. Wang <Jeffrey.Bond.Wang@gmail.com>
% 
% Inputs:
%       sessionDir: Directory for which channel data is found. Files should
%       be of the form LFPx*.ncs, where * is a wildcard
%       line_filter: Logical, setting whether to notch filter at 60,
%       120, and 180 Hz
%       bandpass: two-element vector, giving the low and high frequency
%       cutoffs for frequency, in hz. Set to False for no bandpass
%       filtering
% Output:
%       ftdata_filtered: Fieldtrip structure with preprocessed dataset

%% LOAD DATA WITH FIELDTRIP
cfg=[];
cfg.dataset = sessionDir;
cfg.datafile = 'LFPx*';
cfg.channel = 'LFPx*';
ftdata = ft_preprocessing(cfg); % load w/ fieldtrip

% %% Process Parameters
% i_p = inputParser;
% i_p.FunctionName = 'JW_IMPORT_NEURALYNX';
% 
% addOptional(i_p,'line_filter', true, @islogical);
% addOptional(i_p,'bandpass', [1,200]);
% 
% 
% parse(i_p,varargin{:});
% 
% 
% %% LINE NOISE FILTERING
% cfgi                = []; % other option is BS filter
% cfgi.demean         = 'no';
% cfgi.baselinewindow = 'all';
% 
% % if i_p.Results.line_filter
% %     cfgi.bsfilter       = 'yes';
% %     cfgi.bsfiltord      = 3;
% %     cfgi.bsfreq         = [57 63; 117 123; 177 183]; % use this for NY patients
% % end

%% Bandpass filter
% if ~ i_p.Results.bandpass
%     cfgi.bpfilter       = 'yes';
%     cfgi.bpfilter       = i_p.Results.bandpass;
% end

end