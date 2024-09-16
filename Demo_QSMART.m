clc; clear all; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                   %
% This script is a demo of QSMART pipeline developed                %
% at the Melbourne Brain Centre Imaging Unit.                       %
%                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath('./QSMART_toolbox_v1.0'));
addpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/ants-2.5.3/bin/');
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/frangi_filter_version2a'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/curvatures'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/STISuite_V3.0'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/NIfTI_20140122'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/QSM-master/phase_unwrapping'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/QSM-master/coil_combination'));
addpath(genpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/QSM-master/Misc'));
addpath('/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/STISuite_V3.0/STISuite_V3.0/Core_Functions_P')

global antspath fslpath outpath;
antspath = "/home/unimelb.edu.au/ashishsingh/Documents/Work/installs/ants-2.5.3/bin/";
fslpath = "/home/unimelb.edu.au/ashishsingh/fsl/bin/"
%%% Defining data paths and string IDs%%%
  
datapath_mag='/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/Data/neutral/1.10.1/1.10.1.432/1.10.1.432.1.1/1.10.1.432.1.1.53/dicom_series';
datapath_pha='/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/Data/neutral/1.10.1/1.10.1.432/1.10.1.432.1.1/1.10.1.432.1.1.54/dicom_series';
out_path='./QSMART_out/';
% Path to utility code
qsm_params.mexEig3volume=which('eig3volume.c');

%%% Setting QSM Parameters %%%

% Scanner/Imaging Parameters
qsm_params.species='human';               % 'human' or 'rodent'
qsm_params.field=7;                       % Tesla
qsm_params.gyro=2.675e8;                  % Proton gyromagnetic ratio  
qsm_params.datatype='DICOM_Siemens';      % options: DICOM_Siemens, BRUKER, 'AAR_Siemens', 'ZIP_Siemens'
qsm_params.phase_encoding='unipolar';     % 'unipolar' or 'bipolar'

% Coil combination
qsm_params.coilcombmethod='smooth3';  % options: s(1) smooth3, (2) poly3, (3) poly3_nlcg

% Phase unwrapping 
qsm_params.ph_unwrap_method='laplacian';    %options: 'laplacian','bestpath'

% Threshold parameters
qsm_params.mag_threshold=100;
qsm_params.sph_radius1=2;
qsm_params.sph_radius_vasculature = 8;
qsm_params.adaptive_threshold=0;

% Frangi filter parameters
qsm_params.frangi_scaleRange=[0.5 6];
qsm_params.frangi_scaleRatio=0.5;
qsm_params.frangi_C=500;

% Multiecho fit parameters
qsm_params.fit_threshold=40;

% Background field removal

% Spatial dependent filtering parameters
qsm_params.sdf_sp_radius=8;
qsm_params.s1.sdf_sigma1=10;
qsm_params.s1.sdf_sigma2=0;
qsm_params.s2.sdf_sigma1=8;
qsm_params.s2.sdf_sigma2=2;
qsm_params.sdffilterLowerLim=0.6;
qsm_params.sdffilterCurvConstant=500;

% RESHARP Parameters
qsm_params.resharp.smv_rad = 1;
qsm_params.resharp.tik_reg = 5e-4;
qsm_params.resharp.cgs_num = 500;

% iLSQR Parameters
qsm_params.cgs_num = 500;
qsm_params.inv_num = 500;
qsm_params.smv_rad = .1;

% Adaptive threshold parameters
qsm_params.seg_thres_percentile = 100;
qsm_params.smth_thres_percentile = 100;                % iLSQR-smoothing high-susc segmentation

% Data output
qsm_params.save_raw_data=0;

% QSMART 
start_time = tic
QSMART(datapath_mag,datapath_pha,qsm_params,out_path);    
elapsed_time = toc(start_time)
fprintf('Time required in HH:MM:SS by QSMART : %s', duration([0,0,elapsed_time]))
    

