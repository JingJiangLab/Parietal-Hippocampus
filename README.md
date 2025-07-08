# Parietal-Hippocampus
Preprint: https://www.biorxiv.org/content/10.1101/2025.06.08.658503v1
Both the code for concurrent TMS-iEEG preprocessing and the preprocessed TMS-fMRI dataset (/TMS-fMRI_data) are provided (see the preprint for details). Instructions for using the preprocessing code are described below.

## Aim
Concurrent TMS-iEEG preprocessing

## Toolbox
Download and add the FieldTrip toolbox (https://www.fieldtriptoolbox.org/) to your MATLAB path.

## queue_files
This file specifies input data locations, output filename and paths for processing and saving.

## Scipts
Main Script: demo_preprocess.m, load and preprocess the iEEG data in the /Raw_data. It uses the *P1* (basic preprocessing) and *P2* (detrending) functions below. 

**P1_TMS_iEEG_preprocessing.m**: basic preprocessing, including filtering, artifact interpolation, and re-referencing, downsamlping etc.

**P2_Detrend.m**: remove the TMS decay artifacts after basic preprocessing.


## Raw_data
Raw data are not openly available due to reasons of sensitivity. The provided code was developed using LFP recordings from the Neuralynx system and should be compatible with files saved in similar systems or formats.

## Output
After running demo_preprocess.m, the processed data will be saved in: Preprocessed/SubID/Detrended. Two versions will be generated (BroadFilter: 2–200 Hz; NarrowFilter: 2–35 Hz) with the main variables (ftData_epoch_tms and ftData_epoch_sham).

ftData_epoch_tms.trial: including all trials, each trial was organized as a matrix (Channels × Time).

ftData_epoch_tms.label: Channel names.

ftData_epoch_tms.time: Relative time points for each trial.

ftData_epoch_sham: Structure is identical to ftData_epoch_tms, containing sham condition trials.
