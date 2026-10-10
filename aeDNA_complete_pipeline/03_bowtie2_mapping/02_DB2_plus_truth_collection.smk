import os

# Creates a DB2 logical mapping collection without rebuilding a huge joint index.
# DB2 = existing Standard -k100 outputs + Truth600 -k100 outputs.
# The files are symlinked, not copied, so this costs almost no extra disk space.
# Run e.g.:
# snakemake -s 02_DB2_plus_truth_collection.smk --config age=morden -j 20

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
AGE = config.get("age", "deeptime")
if AGE not in {"morden", "young", "old", "deeptime"}:
    raise ValueError("--config age= must be one of: morden, young, old, deeptime")

AGE_DIR = f"{BASE}/aeDNA_{AGE}"
STD_BAM = f"{AGE_DIR}/bam"
TRUTH_BAM = f"{AGE_DIR}/bam_truth600"
OUT = f"{AGE_DIR}/bam_DB2_plus_truth"

standard_categories = {
    "bacteria": 20,
    "invert": 6,
    "nt": 22,
    "others": 3,
    "vert_mam": 13,
    "vert_other": 13,
}
truth_categories = {
    "aeDNAanimals": 1,
    "aeDNAmicro": 1,
    "aeDNAplants": 1,
}

sample_list = sorted([
    x for x in os.listdir(STD_BAM)
    if os.path.isdir(os.path.join(STD_BAM, x))
])

all_flags = []
for sample in sample_list:
    for cat, count in standard_categories.items():
        for num in range(1, count + 1):
            all_flags.append(f"{OUT}/{sample}/{sample}.{cat}.part_{num}.bam.finished")
    for cat in truth_categories:
        all_flags.append(f"{OUT}/{sample}/{sample}.{cat}.part_1.bam.finished")

rule all:
    input:
        all_flags,
        expand(f"{OUT}/{{sample}}/{{sample}}.DB2_file_manifest.tsv", sample=sample_list)

rule link_standard_into_DB2:
    input:
        bam = STD_BAM + "/{sample}/{sample}.{category}.part_{num}.bam",
        flag = STD_BAM + "/{sample}/{sample}.{category}.part_{num}.bam.finished"
    output:
        bam = OUT + "/{sample}/{sample}.{category}.part_{num}.bam",
        flag = OUT + "/{sample}/{sample}.{category}.part_{num}.bam.finished"
    wildcard_constraints:
        category = "bacteria|invert|nt|others|vert_mam|vert_other"
    shell:
        r'''
        set -euo pipefail
        mkdir -p $(dirname {output.bam})
        ln -sfn {input.bam} {output.bam}
        ln -sfn {input.flag} {output.flag}
        if [ -e {input.bam}.log ]; then
            ln -sfn {input.bam}.log {output.bam}.log
        fi
        '''

rule link_truth_into_DB2:
    input:
        bam = TRUTH_BAM + "/{sample}/{sample}.{category}.part_1.bam",
        flag = TRUTH_BAM + "/{sample}/{sample}.{category}.part_1.bam.finished"
    output:
        bam = OUT + "/{sample}/{sample}.{category}.part_1.bam",
        flag = OUT + "/{sample}/{sample}.{category}.part_1.bam.finished"
    wildcard_constraints:
        category = "aeDNAanimals|aeDNAmicro|aeDNAplants"
    shell:
        r'''
        set -euo pipefail
        mkdir -p $(dirname {output.bam})
        ln -sfn {input.bam} {output.bam}
        ln -sfn {input.flag} {output.flag}
        if [ -e {input.bam}.log ]; then
            ln -sfn {input.bam}.log {output.bam}.log
        fi
        '''

rule make_DB2_manifest:
    input:
        lambda wc: [
            f"{OUT}/{wc.sample}/{wc.sample}.{cat}.part_{num}.bam"
            for cat, count in standard_categories.items()
            for num in range(1, count + 1)
        ] + [
            f"{OUT}/{wc.sample}/{wc.sample}.{cat}.part_1.bam"
            for cat in truth_categories
        ]
    output:
        OUT + "/{sample}/{sample}.DB2_file_manifest.tsv"
    run:
        os.makedirs(os.path.dirname(output[0]), exist_ok=True)
        with open(output[0], "w") as fo:
            fo.write("sample\tdatabase_component\tpart\tpath\n")
            for cat, count in standard_categories.items():
                for num in range(1, count + 1):
                    p = f"{OUT}/{wildcards.sample}/{wildcards.sample}.{cat}.part_{num}.bam"
                    fo.write(f"{wildcards.sample}\t{cat}\t{num}\t{p}\n")
            for cat in truth_categories:
                p = f"{OUT}/{wildcards.sample}/{wildcards.sample}.{cat}.part_1.bam"
                fo.write(f"{wildcards.sample}\t{cat}\t1\t{p}\n")
