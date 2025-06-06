# Parietal-Hippocampus

## Toolbox: 
Download FieldTrip toolbox (https://www.fieldtriptoolbox.org/) and add it into the pathfolder.

## Scipts: 
Main Script:
demo_preprocess.m – The primary script for running the preprocessing pipeline. It uses the P1 (basic preprocessing) and P2 (detrending) functions below.
**P1**: basic preprocessing, including filtering, artifact interpolation, and re-referencing, downsamlping etc.
**P2**: removing the TMS decay artifacts after basic preprocessing.
 
Output
After running demo_preprocess.m, the processed data will be saved in:Preprocessed/SubID/Detrended. Two versions will be generated: BroadFilter: 2–200 Hz; NarrowFilter: 2–35 Hz.
You can then work with the following variables: ftData_epoch_tms and ftData_epoch_sham.
ftData_epoch_tms.trial: Contains all trials (usually 50), each trial was organized as a matrix (Channels × Time). You can do all the analysis you want on this matrix.
ftData_epoch_tms.label: Channel names.
ftData_epoch_tms.time: Relative time points for each trial (should be −1 to +2 seconds around TMS onset).
