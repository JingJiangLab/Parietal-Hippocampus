function ftDataOut = reselect_channels(ftData,channelInfo)

% Select only for channels that are connected
validChannels = strtrim(cellstr(num2str(channelInfo.Channel)));
validChannels = strcat('LFPx',validChannels);

% Now select subset
cfg = [];
cfg.channel = validChannels;
ftDataOut = ft_selectdata(cfg, ftData);

end