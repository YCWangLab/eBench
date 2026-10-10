#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH -o merge_old_animal_plant.%j.out

set -euo pipefail

ROOT="/online1/ycsc_wx/ycwang/aeDNA/old"
mkdir -p "$ROOT/final_animals" "$ROOT/final_plants"

for sample in {1..30}; do
    inputs=(
        "$ROOT/mutation_animals/${sample}_nuclear.sample.fa"
        "$ROOT/mutation_animals/${sample}_mito.sample.fa"
        "$ROOT/mutation_plants/${sample}_nuclear.sample.fa"
        "$ROOT/mutation_plants/${sample}_mito.sample.fa"
        "$ROOT/mutation_plants/${sample}_chlo.sample.fa"
    )
    for input in "${inputs[@]}"; do
        [[ -s "$input" ]] || { echo "ERROR: missing or empty input: $input" >&2; exit 1; }
    done
    cat "${inputs[0]}" "${inputs[1]}" > "$ROOT/final_animals/${sample}.sample.fa"
    cat "${inputs[2]}" "${inputs[3]}" "${inputs[4]}" > "$ROOT/final_plants/${sample}.sample.fa"
done

