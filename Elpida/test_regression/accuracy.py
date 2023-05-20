import csv

myFile = 'test_regression/output_files/results.csv'
num_of_bits = 16

def isclose(a, b, num_of_bits=16, rel_tol=1e-03, abs_tol=0.0001):
    a = a[0]+'b'+a[1:num_of_bits]
    b = b[0]+'b'+b[1:num_of_bits]
    a_int = int(a,2)/2**(num_of_bits-1)
    b_int = int(b,2)/2**(num_of_bits-1)
    return abs(a_int-b_int) <= max(rel_tol * max(abs(a_int), abs(b_int)), abs_tol)

with open(myFile, newline='') as csvfile:
    data = list(csv.reader(csvfile))

correct = 0
print(data)
for test in data:
    # print(int(test[0],2)/2**(num_of_bits-1),'    ',int(test[1],2)/2**(num_of_bits-1))
    # print(isclose(test[0],test[1],num_of_bits))
    if isclose(test[0],test[1],num_of_bits):
        correct=correct+1

print('Accuracy: ',(correct/len(data))*100,'%')