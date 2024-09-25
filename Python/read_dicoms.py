#read_dicoms.py
import os,sys
import SimpleITK as sitk
import numpy as np


def convert_dicom_to_nifti(input_dcm_dir,output_dcm_dir):
    result = os.system("dcm2niix -o " + output_dcm_dir + " " + input_dcm_dir)
    if result > 0:
        print("dcm2niix failed")
        sys.exit(1)
    else:
        print("dcm2niix succeeded")

def read_info_from_dicom_header(input_dcm_dir):
    ph_list = [os.path.join(dp, f) for dp, dn, filenames in os.walk(input_dcm_dir) for f in filenames if os.path.splitext(f)[1] == '.dcm']
    
    # number of slices (mag and ph should be the same)
    nSL = len(ph_list)
    print('nSL: ', nSL)

    #add gdcm scanner to read a few tags from dicom directory
    gdcm_reader = sitk.ImageSeriesReader()
    gdcm_reader.MetaDataDictionaryArrayUpdateOn()
    gdcm_reader.LoadPrivateTagsOn()
    gdcm_reader.SetFileNames(ph_list)
    # gdcm_reader.ReadImageInformation()
    
    # get the sequence parameters
    dir_name, fn= os.path.split(ph_list[-1])
    fnames = [os.path.basename(f) for f in ph_list]
    fnames.sort()

    last_fname = os.path.join(dir_name,fnames[-1])
    dicom_info = sitk.ReadImage(last_fname)
    NumberOfEchoes = int(dicom_info.GetMetaData('0018|0086'))  # EchoNumbers
    print('num echoes: ', NumberOfEchoes)

    TE = {}
    counter = 0
    for i in range(0, nSL, int(nSL/NumberOfEchoes)):
        fn = os.path.join(dir_name,fnames[i])
        dicom_info = sitk.ReadImage(fn)
        TE[dicom_info.GetMetaData('0018|0086')] = dicom_info.GetMetaData('0018|0081')  # EchoTime

    resolution = [dicom_info.GetSpacing()[0], dicom_info.GetSpacing()[1], dicom_info.GetSpacing()[2]]  # voxel dimensions

    # angles (z projections of the image x y z coordinates)
    ImageOrientationPatient = dicom_info.GetMetaData('0020|0037')
    ImageOrientationPatient = [float(i) for i in ImageOrientationPatient.split('\\')]
    Xz = ImageOrientationPatient[2]
    Yz = ImageOrientationPatient[5]
    Zxyz = np.cross(ImageOrientationPatient[0:3], ImageOrientationPatient[3:6])
    Zz = Zxyz[2]
    z_prjs = [Xz, Yz, Zz]

    dicom_dict = {}
    dicom_dict["echo_times"] = TE
    dicom_dict["resolution"] = resolution
    dicom_dict["z_prjs"] = z_prjs

    print('dicom dict: ')
    print(dicom_dict)
    return dicom_dict

#convert_dicom_to_nifti(idir=None,odir=None)
#read_info_from_dicom_header(idir)

# def add(a,b):
#     c = a+b
#     print('sum: ', c)
#     return c

# add(x,y)