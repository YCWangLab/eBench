#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=70000
#SBATCH -o damage_young.%j.out

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_INPUTS_DIR=${COMMON_INPUTS_DIR:-$(cd "$SCRIPT_DIR/../../../01_common_inputs" && pwd)}

ROOT="/online1/ycsc_wx/ycwang/aeDNA/young"
PROFILE="$COMMON_INPUTS_DIR/Damage/young_misincorporation.txt"
DEAMSIM="/online1/ycsc_wx/ycwang/PATH/gargammel/bin/deamSim"
mkdir -p "$ROOT/damaged_fasta"
files=("$ROOT/final_fasta"/*.fa)
(( ${#files[@]} > 0 )) || { echo "ERROR: no FASTA files in $ROOT/final_fasta" >&2; exit 1; }

for fasta in "${files[@]}"; do
    sample=$(basename "$fasta" .fa)
    "$DEAMSIM" -o "$ROOT/damaged_fasta/${sample}_damaged.fa.gz" -name \
        -mapdamage "$PROFILE" double "$fasta"
    gzip -df "$ROOT/damaged_fasta/${sample}_damaged.fa.gz"
done

