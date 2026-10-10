import os

# DB3 approximation without rebuilding Standard-minus-Truth index.
# Input Standard mapping files are TRUE BAM.
# Output DB3 files are also TRUE BAM and preserve query-name order.
# Run e.g.:
# snakemake -s 03_DB3_minus_truth_filter.smk --config age=morden -F --executor slurm -j 20

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
AGE = config.get("age", "deeptime")
if AGE not in {"morden", "young", "old", "deeptime"}:
    raise ValueError("--config age= must be one of: morden, young, old, deeptime")

AGE_DIR = f"{BASE}/aeDNA_{AGE}"
STD_BAM = f"{AGE_DIR}/bam"
OUT = f"{AGE_DIR}/bam_DB3_minus_truth"
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

all_flags = []
for cat, count in categories.items():
    for num in range(1, count + 1):
        for sample in sample_list:
            all_flags.append(
                f"{OUT}/{sample}/{sample}.{cat}.part_{num}.bam.finished"
            )

rule all:
    input:
        all_flags,
        expand(f"{OUT}/{{sample}}/{{sample}}.DB3_filter_summary.tsv", sample=sample_list)

rule filter_truth_alignments:
    input:
        bam = STD_BAM + "/{sample}/{sample}.{category}.part_{num}.bam",
        exact = TRUTH_EXACT,
        noversion = TRUTH_NOVERSION
    output:
        bam = OUT + "/{sample}/{sample}.{category}.part_{num}.bam",
        flag = OUT + "/{sample}/{sample}.{category}.part_{num}.bam.finished",
        stats = OUT + "/{sample}/{sample}.{category}.part_{num}.DB3_filter.stats.tsv"
    params:
        tmp = lambda wc: f"{OUT}/{wc.sample}/{wc.sample}.{wc.category}.part_{wc.num}.bam.tmp"
    wildcard_constraints:
        category = "bacteria|invert|nt|others|vert_mam|vert_other"
    resources:
        mem_mb = 12000,
        time_hours = 8
    threads: 4
    shell:
        r'''
        set -euo pipefail
        mkdir -p $(dirname {output.bam})
        rm -f {params.tmp}

        samtools view -h -@ {threads} {input.bam} \
        | awk -v exact_file="{input.exact}" -v nov_file="{input.noversion}" -v stats="{output.stats}" '
        BEGIN {{
            while ((getline x < exact_file) > 0) exact[x]=1;
            close(exact_file);
            while ((getline x < nov_file) > 0) nov[x]=1;
            close(nov_file);
            header=0; kept=0; removed=0; total=0;
        }}
        /^@/ {{ print; header++; next }}
        {{
            total++;
            r=$3;
            b=r;
            sub(/\.[0-9]+$/, "", b);
            if ((r in exact) || (b in nov)) {{
                removed++;
                next;
            }}
            print;
            kept++;
        }}
        END {{
            print "metric\tcount" > stats;
            print "header_lines\t" header >> stats;
            print "alignment_lines_total\t" total >> stats;
            print "alignment_lines_removed_truth\t" removed >> stats;
            print "alignment_lines_kept\t" kept >> stats;
            if (total > 0) print "fraction_removed\t" removed/total >> stats;
            else print "fraction_removed\t0" >> stats;
        }}' \
        | samtools view -@ {threads} -O BAM -o {params.tmp} -

        samtools quickcheck -v {params.tmp}
        mv -f {params.tmp} {output.bam}
        touch {output.flag}
        '''

rule summarize_DB3_filter:
    input:
        lambda wc: [
            f"{OUT}/{wc.sample}/{wc.sample}.{cat}.part_{num}.DB3_filter.stats.tsv"
            for cat, count in categories.items()
            for num in range(1, count + 1)
        ]
    output:
        OUT + "/{sample}/{sample}.DB3_filter_summary.tsv"
    run:
        total = removed = kept = 0
        rows = []
        for fn in input:
            d = {}
            with open(fn) as f:
                next(f)
                for line in f:
                    k, v = line.rstrip("\n").split("\t", 1)
                    d[k] = v
            t = int(float(d.get("alignment_lines_total", 0)))
            r = int(float(d.get("alignment_lines_removed_truth", 0)))
            k = int(float(d.get("alignment_lines_kept", 0)))
            total += t
            removed += r
            kept += k
            rows.append((fn, t, r, k))
        with open(output[0], "w") as fo:
            fo.write("file\ttotal_alignments\tremoved_truth\tkept\tfraction_removed\n")
            for fn, t, r, k in rows:
                frac = (r / t) if t else 0
                fo.write(f"{fn}\t{t}\t{r}\t{k}\t{frac:.8f}\n")
            frac = (removed / total) if total else 0
            fo.write(f"ALL\t{total}\t{removed}\t{kept}\t{frac:.8f}\n")
