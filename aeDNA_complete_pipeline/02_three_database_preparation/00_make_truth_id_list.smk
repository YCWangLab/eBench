import os

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
TRUTH_DIR = f"{BASE}/genomes/aeDNA_bowtie2"
OUTDIR = f"{BASE}/genomes/aeDNA_truth_ids"

truth_fastas = [
    f"{TRUTH_DIR}/aeDNAanimals.fna",
    f"{TRUTH_DIR}/aeDNAmicro.fna",
    f"{TRUTH_DIR}/aeDNAplants.fna",
]

rule all:
    input:
        f"{OUTDIR}/truth_reference_ids.exact.txt",
        f"{OUTDIR}/truth_reference_ids.noversion.txt",
        f"{OUTDIR}/truth_reference_ids.summary.txt"

rule make_truth_id_list:
    input:
        truth_fastas
    output:
        exact = f"{OUTDIR}/truth_reference_ids.exact.txt",
        noversion = f"{OUTDIR}/truth_reference_ids.noversion.txt",
        summary = f"{OUTDIR}/truth_reference_ids.summary.txt"
    resources:
        mem_mb = 8000,
        time_hours = 2
    shell:
        r'''
        set -euo pipefail
        mkdir -p {OUTDIR}

        cat {input} \
          | awk '/^>/{{sub(/^>/, ""); split($0,a,/[	 ]/); print a[1]}}' \
          | LC_ALL=C sort -u > {output.exact}

        sed -E 's/\.[0-9]+$//' {output.exact} \
          | LC_ALL=C sort -u > {output.noversion}

        {{
          echo "truth FASTA files:"
          printf '%s\n' {input}
          echo
          echo -n "exact sequence IDs: "
          wc -l < {output.exact}
          echo -n "version-stripped sequence IDs: "
          wc -l < {output.noversion}
        }} > {output.summary}
        '''
