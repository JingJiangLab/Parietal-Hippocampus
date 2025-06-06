# Parietal-Hippocampus

## Toolbox: 
Download and add the FieldTrip toolbox (https://www.fieldtriptoolbox.org/) to your MATLAB path.

## queue_files:
This file specifies input data locations and output paths for processing and saving.

## Scipts: 
Main Script: Load and preprocess data in the /Raw_data.

demo_preprocess.m – The primary script for running the preprocessing pipeline. It uses the *P1* (basic preprocessing) and *P2* (detrending) functions below. 

**P1_TMS_iEEG_preprocessing.m**: basic preprocessing, including filtering, artifact interpolation, and re-referencing, downsamlping etc.

**P2_Detrend.m**: remove the TMS decay artifacts after basic preprocessing.


## Output
After running demo_preprocess.m, the processed data will be saved in:Preprocessed/SubID/Detrended. Two versions will be generated (BroadFilter: 2–200 Hz; NarrowFilter: 2–35 Hz) with the main variables (ftData_epoch_tms and ftData_epoch_sham).

ftData_epoch_tms.trial: including all trials, each trial was organized as a matrix (Channels × Time).

ftData_epoch_tms.label: Channel names.

ftData_epoch_tms.time: Relative time points for each trial (should be −1 to +2 seconds in relative to TMS onset).

ftData_epoch_sham: Structure is identical to ftData_epoch_tms, containing sham condition trials.
