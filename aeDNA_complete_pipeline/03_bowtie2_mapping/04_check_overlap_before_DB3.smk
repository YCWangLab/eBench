import os

# Diagnostic only: checks whether Standard mapping RNAMEs overlap the Truth600 IDs.
# This is important because DB3 filtering is only meaningful if the identifiers match.
# Run e.g.:
# snakemake -s 04_check_overlap_before_DB3.smk --config age=morden -j 20

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
AGE = config.get("age", "deeptime")
AGE_DIR = f"{BASE}/aeDNA_{AGE}"
STD_BAM = f"{AGE_DIR}/bam"
OUT = f"{AGE_DIR}/DB3_overlap_check"
TRUTH_ID_DIR = f"{BASE}/genomes/aeDNA_truth_ids"
TRUTH_EXACT = f"{TRUTH_ID_DIR}/truth_reference_ids.exact.txt"
TRUTH_NOVERSION = f"{TRUTH_ID_DIR}/truth_reference_ids.noversion.txt"

categories = {
    "bacteria": 20,
    "invert": 6,
    "nt": 22,
    "others": 3,
    "vert_mam": 13,
    "vert_other": 13,
}

sample_list = sorted([
    x for x in os.listdir(STD_BAM)
    if os.path.isdir(os.path.join(STD_BAM, x))
])

rule all:
    input:
        expand(f"{OUT}/{{sample}}.truth_rname_overlap.tsv", sample=sample_list)

rule check_one_sample:
    input:
        bams = lambda wc: [
            f"{STD_BAM}/{wc.sample}/{wc.sample}.{cat}.part_{num}.bam"
            for cat, count in categories.items()
            for num in range(1, count + 1)
        ],
        exact = TRUTH_EXACT,
        noversion = TRUTH_NOVERSION
    output:
        f"{OUT}/{{sample}}.truth_rname_overlap.tsv"
    resources:
        mem_mb = 8000,
        time_hours = 4
    shell:
        r'''
        set -euo pipefail
        mkdir -p {OUT}
        awk -v exact_file="{input.exact}" -v nov_file="{input.noversion}" '
        BEGIN {{
          while ((getline x < exact_file) > 0) exact[x]=1;
          close(exact_file);
          while ((getline x < nov_file) > 0) nov[x]=1;
          close(nov_file);
          total=0; overlap=0;
        }}
        !/^@/ {{
          total++;
          r=$3; b=r; sub(/\.[0-9]+$/, "", b);
          if ((r in exact) || (b in nov)) overlap++;
        }}
        END {{
          print "metric\tcount";
          print "alignment_lines_total\t" total;
          print "alignment_lines_matching_truth_IDs\t" overlap;
          if (total > 0) print "fraction_matching_truth_IDs\t" overlap/total;
          else print "fraction_matching_truth_IDs\t0";
        }}' {input.bams} > {output}
        '''
