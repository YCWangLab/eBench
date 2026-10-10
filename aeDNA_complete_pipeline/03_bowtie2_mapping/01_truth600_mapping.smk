import os

# Re-run Truth600 mapping and overwrite the original output paths with TRUE BAM.
# Run e.g.:
# snakemake -s 01_truth600_mapping.smk --config age=morden -F --executor slurm -j 20

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
AGE = config.get("age", "deeptime")
if AGE not in {"morden", "young", "old", "deeptime"}:
    raise ValueError("--config age= must be one of: morden, young, old, deeptime")

AGE_DIR = f"{BASE}/aeDNA_{AGE}"
FQ_FOLDER = f"{AGE_DIR}/rawdata"
BAM_FOLDER = f"{AGE_DIR}/bam_truth600"
TRUTH_INDEX_DIR = f"{BASE}/genomes/aeDNA_bowtie2"

truth_categories = {
    "aeDNAanimals": f"{TRUTH_INDEX_DIR}/aeDNAanimals",
    "aeDNAmicro": f"{TRUTH_INDEX_DIR}/aeDNAmicro",
    "aeDNAplants": f"{TRUTH_INDEX_DIR}/aeDNAplants",
}

sample_list = sorted([
    x for x in os.listdir(FQ_FOLDER)
    if os.path.isdir(os.path.join(FQ_FOLDER, x))
    and os.path.isfile(os.path.join(FQ_FOLDER, x, f"{x}.fq"))
])

all_flags = [
    f"{BAM_FOLDER}/{sample}/{sample}.{cat}.part_1.bam.finished"
    for cat in truth_categories
    for sample in sample_list
]

rule all:
    input:
        all_flags

rule truth600_bowtie2_mapping:
    input:
        fq = FQ_FOLDER + "/{sample}/{sample}.fq"
    output:
        bam = BAM_FOLDER + "/{sample}/{sample}.{category}.part_1.bam",
        mapped_flag = BAM_FOLDER + "/{sample}/{sample}.{category}.part_1.bam.finished"
    params:
        ref_index_basename = lambda wc: truth_categories[wc.category],
        tmp = lambda wc: f"{BAM_FOLDER}/{wc.sample}/{wc.sample}.{wc.category}.part_1.bam.tmp"
    wildcard_constraints:
        category = "|".join(truth_categories.keys())
    resources:
        mem_mb = 180000,
        time_hours = 8
    threads: 24
    shell:
        r'''
        set -euo pipefail
        mkdir -p $(dirname {output.bam})
        rm -f {params.tmp}

        bowtie2 --threads 20 \
          -x {params.ref_index_basename} \
          -U {input.fq} \
          -k 100 -L 22 -i S,1,1.15 --mp 1,1 --rdg 0,1 --rfg 0,1 \
          --score-min L,0,-0.1 --no-unal \
          2> {output.bam}.log \
        | samtools sort \
            -n \
            -@ 4 \
            -m 2G \
            -O BAM \
            -o {params.tmp} \
            -

        samtools quickcheck -v {params.tmp}
        mv -f {params.tmp} {output.bam}
        touch {output.mapped_flag}
        '''
