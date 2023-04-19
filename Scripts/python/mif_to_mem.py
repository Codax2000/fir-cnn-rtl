"""
Alex Knowlton
4/18/2023

Script that writes a new .mem file for every .mif file in the mem directory. Make sure to run this
file in the top-level directory.
"""

import os
import re

def convert_mif_to_mem(mif_path, mem_path):
    with open(mif_path) as mif_read:
        with open(mem_path, 'w') as mem_write:
            for line in mif_read.readlines():
                mem_write.writelines(line)

def main():
    cwd = os.getcwd()
    for mem_file in os.listdir(f'{cwd}/mem'):
        file_name_mif = f'{cwd}/mem/{mem_file}'
        file_name_mem = re.sub('mif', 'mem', file_name_mif)
        convert_mif_to_mem(file_name_mif, file_name_mem)

if __name__ == '__main__':
    main()