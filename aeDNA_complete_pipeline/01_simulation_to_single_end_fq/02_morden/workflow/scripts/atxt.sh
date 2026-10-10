#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=70000
 
for a in {1..30}; do
    shuf -i 10-10000 -n 500 > "/online1/ycsc_wx/ycwang/aeDNA/morden/reads/${a}.txt"
done
