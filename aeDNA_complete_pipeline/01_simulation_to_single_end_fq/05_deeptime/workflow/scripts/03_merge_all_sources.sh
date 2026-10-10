#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH -o merge_deeptime_all_sources.%j.out

set -euo pipefail

ROOT="/online1/ycsc_wx/ycwang/aeDNA/deeptime"
mkdir -p "$ROOT/final_fasta"

for sample in {1..30}; do
    micro="$ROOT/mutation_micro/${sample}.sample.fa"
    animals="$ROOT/final_animals/${sample}.fa"
    plants="$ROOT/final_plants/${sample}.fa"

    for input in "$micro" "$animals" "$plants"; do
        [[ -s "$input" ]] || { echo "ERROR: missing or empty input: $input" >&2; exit 1; }
    done

    cat "$micro" "$animals" "$plants" > "$ROOT/final_fasta/${sample}.fa"
done

