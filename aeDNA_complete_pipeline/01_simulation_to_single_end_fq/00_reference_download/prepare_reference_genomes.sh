#!/bin/bash
#SBATCH -p q_amd_share
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=70000
#SBATCH -o reference_genomes.%j.out

# Consolidated Truth600 reference-genome preparation.
# Usage:
#   bash prepare_reference_genomes.sh manifest
#   bash prepare_reference_genomes.sh select SEED
#   bash prepare_reference_genomes.sh download
#   bash prepare_reference_genomes.sh split
#   bash prepare_reference_genomes.sh all

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_INPUTS_DIR=${COMMON_INPUTS_DIR:-$(cd "$SCRIPT_DIR/../01_common_inputs" && pwd)}
SUMMARY_DIR=${SUMMARY_DIR:-$COMMON_INPUTS_DIR/refgenome}
WORK_ROOT=${WORK_ROOT:-$SCRIPT_DIR/work}
PLANT_SUMMARY=${PLANT_SUMMARY:-$SUMMARY_DIR/p_assembly_summary.txt}

SELECTED_LIST_DIR=${SELECTED_LIST_DIR:-$SCRIPT_DIR}
MICRO_LIST="$SELECTED_LIST_DIR/accession_aemicros_list.txt"
ANIMAL_LIST="$SELECTED_LIST_DIR/accession_aeanimals_list.txt"
PLANT_LIST="$SELECTED_LIST_DIR/accession_aeplants_list.txt"

MANIFEST_DIR="$WORK_ROOT/manifests"
DOWNLOAD_DIR="$WORK_ROOT/genomes"
SPLIT_DIR="$WORK_ROOT/split_genomes"

mkdir -p "$MANIFEST_DIR" "$DOWNLOAD_DIR" "$SPLIT_DIR"

require_file() {
    [[ -s "$1" ]] || { echo "ERROR: missing or empty file: $1" >&2; exit 1; }
}

collect_group_manifest() {
    local group=$1
    local accession_list=$2
    shift 2
    local output="$MANIFEST_DIR/${group}.accession_ftp.tsv"
    local temporary="$output.tmp"

    require_file "$accession_list"
    : > "$temporary"

    local summary
    for summary in "$@"; do
        [[ -s "$summary" ]] || continue
        awk -F '\t' '
            NR==FNR { wanted[$1]=1; next }
            $0 !~ /^#/ && ($1 in wanted) && $20 != "na" { print $1 "\t" $20 }
        ' "$accession_list" "$summary" >> "$temporary"
    done

    LC_ALL=C sort -u "$temporary" > "$output"
    rm -f "$temporary"

    cut -f1 "$accession_list" | sed 's/\r$//' | LC_ALL=C sort -u > "$MANIFEST_DIR/${group}.requested.txt"
    cut -f1 "$output" | LC_ALL=C sort -u > "$MANIFEST_DIR/${group}.resolved.txt"
    comm -23 "$MANIFEST_DIR/${group}.requested.txt" "$MANIFEST_DIR/${group}.resolved.txt" \
        > "$MANIFEST_DIR/${group}.unresolved.txt"

    echo "[$group] requested=$(wc -l < "$MANIFEST_DIR/${group}.requested.txt") resolved=$(wc -l < "$MANIFEST_DIR/${group}.resolved.txt") unresolved=$(wc -l < "$MANIFEST_DIR/${group}.unresolved.txt")"
}

build_manifests() {
    local micro_summaries=(
        "$SUMMARY_DIR/a_assembly_summary.txt"
        "$SUMMARY_DIR/b_assembly_summary.txt"
        "$SUMMARY_DIR/f_assembly_summary.txt"
    )
    local animal_summaries=(
        "$SUMMARY_DIR/i_assembly_summary.txt"
        "$SUMMARY_DIR/vm_assembly_summary.txt"
        "$SUMMARY_DIR/vo_assembly_summary.txt"
    )
    local plant_summaries=(
        "$PLANT_SUMMARY"
    )

    local summary
    for summary in "${micro_summaries[@]}" "${animal_summaries[@]}" "${plant_summaries[@]}"; do
        require_file "$summary"
    done

    collect_group_manifest micro "$MICRO_LIST" "${micro_summaries[@]}"
    collect_group_manifest animals "$ANIMAL_LIST" "${animal_summaries[@]}"
    collect_group_manifest plants "$PLANT_LIST" "${plant_summaries[@]}"
}

download_group() {
    local group=$1
    local manifest="$MANIFEST_DIR/${group}.accession_ftp.tsv"
    local destination="$DOWNLOAD_DIR/$group"
    require_file "$manifest"
    mkdir -p "$destination"

    while IFS=$'\t' read -r accession ftp_path; do
        [[ -n "$accession" && -n "$ftp_path" ]] || continue
        assembly=$(basename "$ftp_path")
        url="${ftp_path}/${assembly}_genomic.fna.gz"
        wget -c -P "$destination" "$url"
    done < "$manifest"

    local archives=("$destination"/*.fna.gz)
    (( ${#archives[@]} > 0 )) || { echo "ERROR: no downloaded archives for $group" >&2; exit 1; }
    gzip -dkf "${archives[@]}"
}

download_all() {
    download_group micro
    download_group animals
    download_group plants
}

split_animals() {
    local out="$SPLIT_DIR/animals"
    mkdir -p "$out/nuclear" "$out/mitochondrial"
    local genomes=("$DOWNLOAD_DIR/animals"/*.fna)
    (( ${#genomes[@]} > 0 )) || { echo "ERROR: no animal genomes" >&2; exit 1; }

    for genome in "${genomes[@]}"; do
        sample=$(basename "$genome" .fna)
        seqkit grep -n -r -i -p 'mitochondrion|mitochondrial|mtDNA' "$genome" \
            -o "$out/mitochondrial/${sample}.fna"
        seqkit grep -n -r -i -v -p 'mitochondrion|mitochondrial|mtDNA' "$genome" \
            -o "$out/nuclear/${sample}.fna"
    done
}

split_plants() {
    local out="$SPLIT_DIR/plants"
    mkdir -p "$out/nuclear" "$out/mitochondrial" "$out/chloroplast"
    local genomes=("$DOWNLOAD_DIR/plants"/*.fna)
    (( ${#genomes[@]} > 0 )) || { echo "ERROR: no plant genomes" >&2; exit 1; }

    for genome in "${genomes[@]}"; do
        sample=$(basename "$genome" .fna)
        seqkit grep -n -r -i -p 'mitochondrion|mitochondrial|mtDNA' "$genome" \
            -o "$out/mitochondrial/${sample}.fna"
        seqkit grep -n -r -i -p 'chloroplast|plastid|chloroplastid' "$genome" \
            -o "$out/chloroplast/${sample}.fna"
        seqkit grep -n -r -i -v -p 'mitochondrion|mitochondrial|mtDNA|chloroplast|plastid|chloroplastid' "$genome" \
            -o "$out/nuclear/${sample}.fna"
    done
}

split_all() {
    mkdir -p "$SPLIT_DIR/micro"
    local micro_genomes=("$DOWNLOAD_DIR/micro"/*.fna)
    (( ${#micro_genomes[@]} > 0 )) || { echo "ERROR: no microbial genomes" >&2; exit 1; }
    for genome in "${micro_genomes[@]}"; do
        cp -f "$genome" "$SPLIT_DIR/micro/"
    done
    split_animals
    split_plants
}

case "${1:-}" in
    select)
        [[ -n "${2:-}" ]] || { echo "Usage: $0 select SEED" >&2; exit 2; }
        python3 "$SCRIPT_DIR/select_truth600.py" --summary-dir "$SUMMARY_DIR" \
            --output-dir "$WORK_ROOT/selection" --seed "$2"
        echo "Next: SELECTED_LIST_DIR=$WORK_ROOT/selection bash $0 all"
        ;;
    manifest) build_manifests ;;
    download) download_all ;;
    split) split_all ;;
    all) build_manifests; download_all; split_all ;;
    *) echo "Usage: $0 {select SEED|manifest|download|split|all}" >&2; exit 2 ;;
esac

