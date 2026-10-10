#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH -o merge_young_animal_plant.%j.out

set -euo pipefail

ROOT="/online1/ycsc_wx/ycwang/aeDNA/young"
mkdir -p "$ROOT/final_animals" "$ROOT/final_plants"

for sample in {1..30}; do
    animal_nuclear="$ROOT/mutation_animals/${sample}_nuclear.sample.fa"
    animal_mito="$ROOT/mutation_animals/${sample}_mito.sample.fa"
    plant_nuclear="$ROOT/mutation_plants/${sample}_nuclear.sample.fa"
    plant_mito="$ROOT/mutation_plants/${sample}_mito.sample.fa"
    plant_chlo="$ROOT/mutation_plants/${sample}_chlo.sample.fa"

    for input in "$animal_nuclear" "$animal_mito" "$plant_nuclear" "$plant_mito" "$plant_chlo"; do
        [[ -s "$input" ]] || { echo "ERROR: missing or empty input: $input" >&2; exit 1; }
    done

    cat "$animal_nuclear" "$animal_mito" > "$ROOT/final_animals/${sample}.sample.fa"
    cat "$plant_nuclear" "$plant_mito" "$plant_chlo" > "$ROOT/final_plants/${sample}.sample.fa"
done

