"""
Alex Knowlton
4/18/2023

Script that writes old n_n_n.mem files to n_n_00n.mem files to match updated ROM
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
        file_name_mem = re.sub('', 'mem', file_name_mif)
        convert_mif_to_mem(file_name_mif, file_name_mem)

if __name__ == '__main__':
    main()