function [cortical_labels, bipolar_labelold, bipolar_labelnew, bipolar_tra, channelInfoNew] = generate_reref_matrix(channelInfo)
%% Sort all channels by group, then channel number
channelInfoSorted = sortrows(channelInfo,{'Group', 'Channel'});

%% Find all depth electrodes
depth_electrodes = contains(lower(channelInfoSorted{:,'Group'}),'depth');
depth_groups = findgroups(channelInfoSorted{depth_electrodes,'Group'});

num_groups = max(depth_groups);
num_total = height(channelInfoSorted);
num_depths = sum(depth_electrodes);
num_corticals = num_total - num_depths;

%% Initialize Variables
bipolar_tra = zeros(num_depths - num_groups,num_depths); % Adjacency Matrix for Bipolar Montage
cortical_labels = cell(num_corticals,1); % Cortical Electrode Names
bipolar_labelold = cell(num_depths,1); % Depth Electrode Names
bipolar_labelnew = cell(num_depths - num_groups,1); % Bipolar Electrode Names
channelInfoNew = channelInfo(1:num_total - num_groups,:);

depth_idx_new = 1;
depth_idx_old = 1;
cortical_idx = 1;

for ch = 1:height(channelInfoSorted)
    % Check if a depth electrode
    if depth_electrodes(ch)
        % Always add to old labels
        bipolar_labelold{depth_idx_old} = strjoin({'LFPx',num2str(channelInfoSorted{ch,'Channel'})},'');
        
        % Then see if next electrode is in the same group, then create a new
        % bipolar electrode
        if depth_idx_old <= num_depths - 1 && depth_groups(depth_idx_old) == depth_groups(depth_idx_old + 1)
            bipolar_tra(depth_idx_new,depth_idx_old) = 1;
            bipolar_tra(depth_idx_new,depth_idx_old + 1) = -1;
            bipolar_labelnew{depth_idx_new} = strcat('LFPx',num2str(channelInfoSorted{ch,'Channel'})); %,'-',num2str(channelInfoSorted{ch+1,'Channel'})
            
            channelInfoNew(cortical_idx + depth_idx_new - 1,:) = channelInfoSorted(ch,:);
            
            channelInfoNew{cortical_idx + depth_idx_new - 1,'mniX'} = (channelInfoSorted{ch,'mniX'} + channelInfoSorted{ch+1,'mniX'}) / 2;
            channelInfoNew{cortical_idx + depth_idx_new - 1,'mniY'} = (channelInfoSorted{ch,'mniY'} + channelInfoSorted{ch+1,'mniY'}) / 2;
            channelInfoNew{cortical_idx + depth_idx_new - 1,'mniZ'} = (channelInfoSorted{ch,'mniZ'} + channelInfoSorted{ch+1,'mniZ'}) / 2;
            
            channelInfoNew{cortical_idx + depth_idx_new - 1,'anatX'} = (channelInfoSorted{ch,'anatX'} + channelInfoSorted{ch+1,'anatX'}) / 2;
            channelInfoNew{cortical_idx + depth_idx_new - 1,'anatY'} = (channelInfoSorted{ch,'anatY'} + channelInfoSorted{ch+1,'anatY'}) / 2;
            channelInfoNew{cortical_idx + depth_idx_new - 1,'anatZ'} = (channelInfoSorted{ch,'anatZ'} + channelInfoSorted{ch+1,'anatZ'}) / 2;
            
            depth_idx_new = depth_idx_new + 1;
        end
        
        depth_idx_old = depth_idx_old + 1;
    else
        % Otherwise just add it to all other cortical electrodes for mean
        % rereferencing
        cortical_labels{cortical_idx} = strjoin({'LFPx',num2str(channelInfoSorted{ch,'Channel'})},'');
        channelInfoNew(cortical_idx + depth_idx_new - 1,:) = channelInfoSorted(ch,:);
        cortical_idx = cortical_idx + 1;
    end
end

channelInfoNew = sortrows(channelInfoNew,'Channel');

end