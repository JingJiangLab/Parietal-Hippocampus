function [trigTimes, trigLengths] = jw_extract_trig_times(fname,thres,negative)
% JW_EXTRACT_TRIG_TIMES reads an incoming trigger and returns the event
% timings for when the trigger goes high
%
% Author: Jeffrey B. Wang <Jeffrey.Bond.Wang@gmail.com>
% 
% Inputs:
%       fname: Name of input .ncs file with the trigger
%       thres: Threshold (in voltage) above which a trigger is active
% Output:
%       trigTimes: List of floating points representing the time for when
%       the trigger is active, in seconds
%       trigLengths: List of floating points representing the length of
%       each trigger, in seconds


%% IMPORT DATA

hdr = ft_read_header(fname);
trigInput = ft_read_data(fname);
inputTime = 0:(length(trigInput) - 1);
inputTime = inputTime / hdr.Fs;
plot(inputTime,trigInput)

if negative
    trigInput = trigInput * -1;
end


%% Segment out when TMS is on
if isnan(thres)
    thres = (min(trigInput) + max(trigInput)) / 2; %mark
end
tmsOn = logical(trigInput > thres);
boundingBoxes = extractfield(regionprops(tmsOn, 'BoundingBox'),'BoundingBox');
boundingBoxes = reshape(boundingBoxes,4,[]);

%% Extract Starting times and how long each trigger lasted
trigTimes = inputTime(cast(boundingBoxes(1,:),'uint32'));
trigLengths = boundingBoxes(3,:) / hdr.Fs;



end