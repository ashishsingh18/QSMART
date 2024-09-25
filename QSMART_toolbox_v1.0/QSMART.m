function QSMART(path_mag,path_pha,params,path_out)

params.ppm= (params.gyro*params.field)/1e6; %ppm multiplier

% define output directories
mkdir(path_out); %creates the folder
cd(path_out); %goes to the new created folder

% read in DICOMs of both uncombined magnitude and raw unfiltered phase images
% [mag_all,ph_all,params.iminfo]= readComplexDicoms(path_mag,path_pha);
% fprintf('dicom_info.echo_times : %s\n', params.iminfo.echo_times)
% fprintf('dicom_info.resolution : %s\n', params.iminfo.resolution)
% fprintf('dicom_info.z_prjs : %s\n', params.iminfo.z_prjs)
% fprintf('dicom_info : %s\n', params.iminfo)

% return;

% convert mag dicom into nii and save them in output folder.
% use dcm2nnix from python for dicom to nii conversion
mag_nii_out = "/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python-out/mag_nii_out";
ph_nii_out = "/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python-out/ph_nii_out";
mkdir(mag_nii_out);
mkdir(ph_nii_out);

% convert mag dicom to nii
terminate(pyenv)
pyenv(ExecutionMode="OutOfProcess")
%pyrunfile("/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python/read_dicoms.py", idir=path_mag,odir=mag_nii_out);
%py.importlib.reload('read_dicoms')
if count(py.sys.path,'/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python') == 0
    insert(py.sys.path,int32(0),'/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python');
end
py.importlib.import_module('read_dicoms')
py.read_dicoms.convert_dicom_to_nifti(input_dcm_dir=path_mag,output_dcm_dir=mag_nii_out)

% convert ph dicom to nii
%terminate(pyenv)
%pyenv(ExecutionMode="OutOfProcess")
%pyrunfile("/home/unimelb.edu.au/ashishsingh/Documents/Work/qsm/QSMART-fork/Python/read_dicoms.py", idir=path_pha,odir=ph_nii_out);
py.read_dicoms.convert_dicom_to_nifti(input_dcm_dir=path_pha,output_dcm_dir=ph_nii_out)

retVal = py.read_dicoms.read_info_from_dicom_header(input_dcm_dir=path_pha)

% Extracting echo_times
echo_times = [str2double(char(retVal{'echo_times'}{'1 '})), ...
              str2double(char(retVal{'echo_times'}{'2 '})), ...
              str2double(char(retVal{'echo_times'}{'3 '})), ...
              str2double(char(retVal{'echo_times'}{'4 '}))];

% Extracting resolution
resolution = cell2mat(cell(retVal{'resolution'}));

% Extracting z_prjs
z_prjs = cell2mat(cell(retVal{'z_prjs'}));

% Display the extracted values
disp('Echo Times:');
disp(echo_times);

disp('Resolution:');
disp(resolution);

disp('Z Projections:');
disp(z_prjs);

params.iminfo.echo_times = echo_times;
params.iminfo.resolution = resolution;
params.iminfo.z_prjs = z_prjs;

% disp('params.iminfo:');
% disp(params.iminfo);
return;

% initial quick brain mask
mask=brainmask(mag_all,params);

% coil combination
[ph_corr,mag_corr]=coil_comb(mag_all,ph_all,params.iminfo.resolution,params.iminfo.echo_times,mask,params.phase_encoding,params.coilcombmethod);

% Generating mask of vasculature
vasc_only= vasculature_mask(mag_corr,mask,params);

% Phase unwrapping
unph=unwrap_phase(ph_corr,mask,params.iminfo.resolution, params.ph_unwrap_method);

% Echo fit - fit phase images with echo times
disp('--> magnitude weighted LS fit of phase to TE ...');
[tfs,R_0] = echofit(unph,mag_corr,0,params);

% cleaning the total field shift to find local field shift
lfs_sdf = QSMART_SDF(tfs,mask,R_0,[],1,params);
   
disp('---runnig QSM inversion step 1---');
chi_iLSQR_1 = QSM_iLSQR(lfs_sdf,mask.*R_0,'H',params.iminfo.z_prjs,'voxelsize',params.iminfo.resolution,...
              'niter',50,'TE',1000,'B0',params.field);
nii = make_nii(chi_iLSQR_1,params.iminfo.resolution); save_nii(nii,'QSM_1.nii');

disp('---runnig QSM inversion step 2---');
lfs_sdf_2 = QSMART_SDF(tfs,mask,R_0,vasc_only,2,params);
chi_iLSQR_2 = QSM_iLSQR(lfs_sdf_2,mask.*vasc_only.*R_0,'H',params.iminfo.z_prjs,'voxelsize',params.iminfo.resolution,...
              'niter',50,'TE',1000,'B0',params.field);
nii = make_nii(chi_iLSQR_2,params.iminfo.resolution); save_nii(nii,'QSM_2.nii');

% Combining 2-stage chi maps
adjust_offset(mask.*R_0 - vasc_only,lfs_sdf,chi_iLSQR_1,chi_iLSQR_2,params);
    
 disp('--- Process Finished ---');
