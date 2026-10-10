import os

# Re-run Standard mapping and overwrite the original output paths with TRUE BAM.
# Run e.g.:
# snakemake -s original_snakemake_aeDNA_mapping.ver1.250815.smk --config age=morden -F --executor slurm -j 50
# age must be one of: morden, young, old, deeptime

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"
AGE = config.get("age", "morden")
if AGE not in {"morden", "young", "old", "deeptime"}:
    raise ValueError("--config age= must be one of: morden, young, old, deeptime")

fq_folder = f"{BASE}/aeDNA_{AGE}/rawdata"
bam_folder = f"{BASE}/aeDNA_{AGE}/bam"

# Keep the original six Standard database categories and shard counts unchanged.
categories = {
    "bacteria": 20,
    "invert": 6,
    "nt": 22,
    "others": 3,
    "vert_mam": 13,
    "vert_other": 13
}

# Only accept sample directories containing {sample}.fq.
sample_list = sorted([
    x for x in os.listdir(fq_folder)
    if os.path.isdir(os.path.join(fq_folder, x))
    and os.path.isfile(os.path.join(fq_folder, x, f"{x}.fq"))
])

all_flags = []
for cat, count in categories.items():
    for num in range(1, count + 1):
        for sample in sample_list:
            all_flags.append(
                f"{bam_folder}/{sample}/{sample}.{cat}.part_{num}.bam.finished"
            )

rule all:
    input:
        all_flags

rule bowtie2_mapping:
    input:
        fq = fq_folder + "/{sample}/{sample}.fq"
    output:
        bam = bam_folder + "/{sample}/{sample}.{category}.part_{num}.bam",
        mapped_flag = bam_folder + "/{sample}/{sample}.{category}.part_{num}.bam.finished"
    params:
        ref_index_basename = "/online1/ycsc_wx/liuz/database/NCBI_2401/{category}/{category}.{num}",
        tmp = lambda wc: f"{bam_folder}/{wc.sample}/{wc.sample}.{wc.category}.part_{wc.num}.bam.tmp"
    resources:
        mem_mb = 180000,
        time_hours = 8
    # 20 threads remain assigned to bowtie2; 4 additional threads are for samtools sort.
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
