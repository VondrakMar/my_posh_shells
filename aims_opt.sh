#!/bin/bash

# Thin uncomment if you want to take a filename as an argument
# if [ "$#" -ne 1 ]; then
#     echo "Usage: $0 filename"
#     exit 1
# fi
# 
# filename=$1
# if [ ! -f "$filename" ]; then
#     echo "File not found!"
#     exit 1
# fi
if [ -f "opt_aims.xyz" ]; then
    echo "hello seamn"
    rm opt_aims.xyz
fi


filename=aims.out

awk '/Relaxation step number      1: Predicting new coordinates./{flag=1; next} flag' "$filename" | grep -E 'lattice_vector|atom_frac' | grep -v '|' > temp

python -c "
from ase.io import read,write
f = open('temp','r').readlines()
count_lat = 0
file_num = 0
wrt_file = open(f'struc{file_num:04d}.in','w')
for line in f:
    if 'lattice_vector' in line:
        count_lat += 1
    if count_lat == 4:
        wrt_file.close() 
        file_num += 1 
        wrt_file = open(f'struc{file_num:04d}.in','w')
        count_lat = 1
    wrt_file.write(line)
wrt_file.close()
"

for struc in struc*in 
do 
    ase convert $struc ${struc::-3}.xyz -i aims -o extxyz
    cat ${struc::-3}.xyz >> opt_aims.xyz
done
rm temp struc*in struc*xyz
