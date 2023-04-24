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
        if ((mem_file[-2:] == 'em') and (mem_file[-5] != 't')):
            file_name_mif = f'{cwd}/mem/{mem_file}'
            file_name_first = f'{file_name_mif[0:-5]}00{file_name_mif[-5:]}'
            convert_mif_to_mem(file_name_mif, file_name_first)

if __name__ == '__main__':
    main()