#!/bin/python3

########################################
## https://www.hackerrank.com/challenges/angry-children/problem
## a simple greedy algo
########################################

import os

def maxMin(k, arr):
    ordered_arr = sorted(arr)
    
    min_unfairness = float('infinity')
    for start_ix in range(0, len(ordered_arr) - k + 1):
        unfairness = ordered_arr[start_ix + k - 1] - ordered_arr[start_ix]
        if unfairness < min_unfairness:
            min_unfairness = unfairness
    
    return min_unfairness

if __name__ == '__main__':
    fptr = open(os.environ['OUTPUT_PATH'], 'w')

    n = int(input())

    k = int(input())

    arr = []

    for _ in range(n):
        arr_item = int(input())
        arr.append(arr_item)

    result = maxMin(k, arr)

    fptr.write(str(result) + '\n')

    fptr.close()

