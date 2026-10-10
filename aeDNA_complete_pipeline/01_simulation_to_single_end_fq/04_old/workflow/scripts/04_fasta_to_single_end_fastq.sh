#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10000
#SBATCH -o old_fasta_to_fastq.%j.out

set -euo pipefail
shopt -s nullglob

INPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/old/damaged_fasta"
OUTPUT_DIR="/online1/ycsc_wx/ycwang/aeDNA/old/damaged_fq"
REFORMAT="/online1/ycsc_wx/liuz/software/bbmap/reformat.sh"

mkdir -p "$OUTPUT_DIR"
files=("$INPUT_DIR"/*.fa)
(( ${#files[@]} > 0 )) || { echo "ERROR: no FASTA files in $INPUT_DIR" >&2; exit 1; }

for fasta in "${files[@]}"; do
    sample=$(basename "$fasta" .fa)
    "$REFORMAT" in="$fasta" out="$OUTPUT_DIR/$sample.fq" qfake=40
done

