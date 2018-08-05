#!/bin/python3
##############################################
## https://www.hackerrank.com/challenges/triple-sum/problem
## counting distinct integer triplets subject to some constraints using ordering instead of explicitly storing and counting 
##############################################

import os

def triplets(a, b, c):
    a_ordered = sorted(set(a)) # since the triplets must be distinct
    b_ordered = sorted(set(b))
    c_ordered = sorted(set(c))

    total_triplets = 0
    p_ix = 0 # we keep track of indices to keep things to one scan through each a/c array
    r_ix = 0
    for q in b_ordered:
        while p_ix < len(a_ordered) and a_ordered[p_ix] <= q:
            p_ix += 1
        while r_ix < len(c_ordered) and c_ordered[r_ix] <= q:
            r_ix += 1
        
        total_triplets += p_ix * r_ix   
    
    return total_triplets

if __name__ == '__main__':
    fptr = open(os.environ['OUTPUT_PATH'], 'w')

    lenaLenbLenc = input().split()

    lena = int(lenaLenbLenc[0])

    lenb = int(lenaLenbLenc[1])

    lenc = int(lenaLenbLenc[2])

    arra = list(map(int, input().rstrip().split()))

    arrb = list(map(int, input().rstrip().split()))

    arrc = list(map(int, input().rstrip().split()))

    ans = triplets(arra, arrb, arrc)

    fptr.write(str(ans) + '\n')

    fptr.close()

