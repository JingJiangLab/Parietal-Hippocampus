function clean = dh_cleanartifact_interp(data,trigTimes,prebuffer,postbuffer,useSIGNI)
% DH_CLEANARTIFACT_INTERP removes large artifacts by using z-value artifact
% detection followed by SIGNIS interpolation
%
% Author: Danny Huang, adapted into function by Jeffrey B. Wang
%
% Inputs:
%       data: Original EEG, in the Fieldtrip "raw" format
%       trigTimes: Time (in seconds) for when the artifacts occur
%       buffer: how long (in seconds) to scrub beyond each trigger time
% Output:
%       clean: Fieldtrip structure of the cleaned data
% 
% cfgir = [];
% cfgir.continuous = 'yes';
% 
% % channel selection, cutoff and padding
% cfgir.artfctdef.zvalue.channel    = 'all'; % YOU CAN SPECIFY CHANNEL USED FOR ARTIFACT DETECTION, HERE I USE ALL CHANNELS
% cfgir.artfctdef.zvalue.cutoff     = cutoff; % THE CUT OFF THRESHOLD TO PICKING ARTIFACT. 50 SEEMS TO PICK UP ONLY THE STIM ARTIFACTS
% %cfgir.artfctdef.zvalue.trlpadding = -0.1; % to prevent edge artifact recognition
% %cfgir.artfctdef.zvalue.artpadding = 0.01;
% %cfgir.artfctdef.zvalue.fltpadding = 0.1;
% 
% % algorithmic parameters to detect artifacts, TMS artifact should be
% % high-frequency?
% cfgir.artfctdef.zvalue.bpfilter   = 'yes';
% cfgir.artfctdef.zvalue.bpfilttype = 'but';
% cfgir.artfctdef.zvalue.bpfreq     = [150 200]; %[1 200];
% cfgir.artfctdef.zvalue.bpfiltord  = 4;
% cfgir.artfctdef.zvalue.baselinewindow = [80 110];
% cfgir.artfctdef.zvalue.hilbert    = 'yes';
% %cfgir.artfctdef.zvalue.rectify    = 'yes';
% 
% % make the process interactive
% cfgir.artfctdef.zvalue.interactive = 'no';
% 
% [~, artifact_stim] = ft_artifact_zvalue(cfgir, data);

%%  reject artfact
cfgi = [];
cfgi.artfctdef.reject = 'nan';
cfgi.artfctdef.feedback = 'no';
cfgi.artfctdef.xxx.artifact = zeros(length(trigTimes),2);
cfgi.artfctdef.xxx.artifact(:,1) = round((trigTimes - prebuffer) * data.fsample);
cfgi.artfctdef.xxx.artifact(:,2) = round((trigTimes + postbuffer) * data.fsample);
spikeTrain_ft_nan = ft_rejectartifact(cfgi, data);

%% Interpolate nans using cubic interpolation
cfgi = [];
cfgi.method = 'pchip'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
%cfgi.method = 'cubic'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
cfgi.prewindow = 0.01; % Window prior to segment to use data points for interpolation
cfgi.postwindow = 0.01; % Window after segment to use data points for interpolation
cfgi.useSIGNI = useSIGNI;

if sum(isnan(spikeTrain_ft_nan.trial{1}),'All')
    clean = dh_interpolatenan(cfgi, spikeTrain_ft_nan); % Clean data
else
    clean = data;
end