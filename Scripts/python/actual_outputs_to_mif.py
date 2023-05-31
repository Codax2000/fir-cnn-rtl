
def convert_csv_to_mif(data_file):
    new_mif = open('./mem/test_mem_files/test_outputs_measured.mif', 'w')
    with open(data_file) as f:
        for line in f.readlines():
            print(line)
            result = line.strip().split(',')
            result.reverse()
            result = ''.join(result)
            print(result)
            new_mif.write(result)
            new_mif.write('\n')
    new_mif.close()

def main():
    convert_csv_to_mif('./mem/test_values/test_outputs_actual.csv')

if __name__ == '__main__':
    main()