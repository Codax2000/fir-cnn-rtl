import os

def main():
    cwd = f'{os.getcwd()}/mem/'
    for file_name in os.listdir(cwd):
        if ((len(file_name) == len('0_0_0.mif')) or (file_name[0:2] == 'bn')):
            path = f'{cwd}{file_name}'
            print(path)
            os.remove(path)



if __name__ == '__main__':
    main()