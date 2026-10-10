#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=70000
#SBATCH -o damage_deeptime.%j.out

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_INPUTS_DIR=${COMMON_INPUTS_DIR:-$(cd "$SCRIPT_DIR/../../../01_common_inputs" && pwd)}

INPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/deeptime/final_fasta"
OUTPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/deeptime/damaged_fasta"
PROFILE="$COMMON_INPUTS_DIR/Damage/veryold_misincorporation.txt"
DEAMSIM="/online1/ycsc_wx/ycwang/PATH/gargammel/bin/deamSim"

mkdir -p "$OUTPUT_DIR"
files=("$INPUT_DIR"/*.fa)
(( ${#files[@]} > 0 )) || { echo "ERROR: no FASTA files in $INPUT_DIR" >&2; exit 1; }

for fasta in "${files[@]}"; do
    sample=$(basename "$fasta" .fa)
    "$DEAMSIM" -o "$OUTPUT_DIR/${sample}_damaged.fa.gz" -name \
        -mapdamage "$PROFILE" double "$fasta"
    gzip -df "$OUTPUT_DIR/${sample}_damaged.fa.gz"
done

