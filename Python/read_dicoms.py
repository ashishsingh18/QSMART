import os,sys

#print('Hello from Conda Python')
# print('python version: ', sys.version)

def convert_dicom_to_nifti(input_dcm_dir,output_dcm_dir):
    result = os.system("dcm2niix -o " + output_dcm_dir + " " + input_dcm_dir)
    if result > 0:
        print("dcm2niix failed")
        sys.exit(1)
    else:
        print("dcm2niix succeeded")

convert_dicom_to_nifti(i,o)

# def add(a,b):
#     c = a+b
#     print('sum: ', c)
#     return c

# add(x,y)