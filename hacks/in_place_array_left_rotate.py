#!/bin/python3

import os

def gcd(a,b):
    if b == 0:
        return a
    return gcd(b, a%b)

# Complete the rotLeft function below.
def rotLeft(a, d):
    # do it in place, because why not?!
    
    n = len(a)
    n_cycles = gcd(n,d)
    cycle_length = int(n / n_cycles) # this is guaranteed to be an integer by def of gcd
    # this is a fun approach that amounts to chasing the replaced value until everybody has been moved. we have to be cognizant of cycles
    for cycle_start_ix in range(n_cycles):
        current_ix = cycle_start_ix
        current_value = a[current_ix]
        for _ in range(cycle_length):
            target_ix = (current_ix - d) % n
            replaced_value = a[target_ix]
            a[target_ix] = current_value
            current_ix = target_ix
            current_value = replaced_value
        
    return(a)

# https://www.hackerrank.com/challenges/ctci-array-left-rotation/problem
# input format is a first line with array length *space* number of left rotations to perform
# second line is the array of values
# note that it would be much easier to just to plop the values into a list in the correct order from the get go, but this problem was much more fun practicing in place rotation on the original array :)
if __name__ == '__main__':
    fptr = open(os.environ['OUTPUT_PATH'], 'w')

    nd = input().split()

    n = int(nd[0])

    d = int(nd[1])

    a = list(map(int, input().rstrip().split()))

    result = rotLeft(a, d)

    fptr.write(' '.join(map(str, result)))
    fptr.write('\n')

    fptr.close()
