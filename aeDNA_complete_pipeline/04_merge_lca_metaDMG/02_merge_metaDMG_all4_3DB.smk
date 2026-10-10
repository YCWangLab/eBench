import os

BASE = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database"

NODES = "/online1/ycsc_wx/liuz/database/NCBI_2401/taxonomy/dmp/nodes.dmp"
NAMES = "/online1/ycsc_wx/liuz/database/NCBI_2401/taxonomy/dmp/names.dmp"

STD_ACC2TAX = "/online1/ycsc_wx/liuz/database/NCBI_2401/taxonomy/nucl_gb_acc2tax_202401"
DB2_ACC2TAX = BASE + "/genomes/aeDNA_acc2taxid/threeDB/DB2_standard_plus_truth.acc2taxid"

AGES = ["morden", "young", "old", "deeptime"]
ANCIENT_AGES = ["young", "old", "deeptime"]
DBS = ["DB1_standard", "DB2_plus_truth", "DB3_minus_truth"]

STD_CATEGORIES = {
    "bacteria": 20,
    "invert": 6,
    "nt": 22,
    "others": 3,
    "vert_mam": 13,
    "vert_other": 13,
}

TRUTH_CATEGORIES = ["aeDNAanimals", "aeDNAmicro", "aeDNAplants"]


def age_root(age):
    return f"{BASE}/aeDNA_{age}"


def discover_samples(age):
    rawdir = f"{age_root(age)}/rawdata"
    if not os.path.isdir(rawdir):
        return []

    samples = []
    for sample in sorted(os.listdir(rawdir)):
        fq = os.path.join(rawdir, sample, f"{sample}.fq")
        if os.path.isfile(fq):
            samples.append(sample)
    return samples


SAMPLES = {age: discover_samples(age) for age in AGES}

for age in AGES:
    print(f"[{age}] {len(SAMPLES[age])} samples: {SAMPLES[age]}")


def standard_parts(age, sample, bam_root):
    files = []
    for category, number in STD_CATEGORIES.items():
        for part in range(1, number + 1):
            files.append(
                f"{age_root(age)}/{bam_root}/{sample}/{sample}.{category}.part_{part}.bam"
            )
    return files


def truth_parts(age, sample):
    return [
        f"{age_root(age)}/bam_truth600/{sample}/{sample}.{category}.part_1.bam"
        for category in TRUTH_CATEGORIES
    ]


def merge_inputs(wc):
    if wc.db == "DB1_standard":
        return standard_parts(wc.age, wc.sample, "bam")

    if wc.db == "DB2_plus_truth":
        return standard_parts(wc.age, wc.sample, "bam") + truth_parts(wc.age, wc.sample)

    if wc.db == "DB3_minus_truth":
        return standard_parts(wc.age, wc.sample, "bam_DB3_minus_truth")

    raise ValueError(f"Unknown database: {wc.db}")


def acc2tax_for_db(wc):
    if wc.db == "DB2_plus_truth":
        return DB2_ACC2TAX
    return STD_ACC2TAX


def max_len_for_age(wc):
    # morden: no <200 bp filter, only LCA baseline
    # young/old/deeptime: keep SEQ length <200 bp for metaDMG
    return 0 if wc.age == "morden" else 200


FINAL_OUTPUTS = []

# morden: stop at LCA
for sample in SAMPLES["morden"]:
    for db in DBS:
        FINAL_OUTPUTS.append(
            f"{BASE}/aeDNA_morden/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.lca.done"
        )

# young/old/deeptime: full metaDMG chain
for age in ANCIENT_AGES:
    for sample in SAMPLES[age]:
        for db in DBS:
            FINAL_OUTPUTS.append(
                f"{BASE}/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.aggregate.done"
            )


rule all:
    input:
        FINAL_OUTPUTS


rule merge_compact_bam:
    input:
        merge_inputs
    output:
        bam=BASE + "/aeDNA_{age}/threeDB/{db}/bam/{sample}/{sample}.merged.sorted.bam"
    log:
        BASE + "/aeDNA_{age}/threeDB/{db}/logs/{sample}.merge_compact.log"
    wildcard_constraints:
        age="morden|young|old|deeptime",
        db="DB1_standard|DB2_plus_truth|DB3_minus_truth"
    threads:
        10
    resources:
        mem_mb=60000
    params:
        script="scripts/merge_compact_bam.py",
        max_len=max_len_for_age
    shell:
        r"""
        set -euo pipefail

        OUT="{output.bam}"
        OUTDIR=$(dirname "$OUT")
        TMPDIR="$OUTDIR/{wildcards.sample}.compact_tmp"

        mkdir -p "$OUTDIR"
        mkdir -p "$(dirname "{log}")"
        rm -rf "$TMPDIR"
        mkdir -p "$TMPDIR"

        echo "===== START MERGE =====" > "{log}"
        date >> "{log}"
        echo "age={wildcards.age}" >> "{log}"
        echo "db={wildcards.db}" >> "{log}"
        echo "sample={wildcards.sample}" >> "{log}"
        echo "threads={threads}" >> "{log}"
        echo "max_len={params.max_len}" >> "{log}"
        echo "tmpdir=$TMPDIR" >> "{log}"

        echo "===== DISK =====" >> "{log}"
        df -h "$OUTDIR" >> "{log}" 2>&1 || true

        echo "===== MEMORY =====" >> "{log}"
        free -h >> "{log}" 2>&1 || true

        echo "===== PYTHON MERGE =====" >> "{log}"
        python "{params.script}" \
            --output "$OUT" \
            --tmpdir "$TMPDIR" \
            --threads {threads} \
            --max-len {params.max_len} \
            {input} \
            >> "{log}" 2>&1

        echo "===== PYTHON FINISHED =====" >> "{log}"
        file "$OUT" >> "{log}" 2>&1
        samtools quickcheck -v "$OUT" >> "{log}" 2>&1

        echo "===== SUCCESS MERGE =====" >> "{log}"
        date >> "{log}"
        rm -rf "$TMPDIR"
        """


rule metaDMG_lca:
    input:
        bam=rules.merge_compact_bam.output.bam,
        nodes=NODES,
        names=NAMES,
        acc2tax=acc2tax_for_db
    output:
        bdamage=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.lca.bdamage.gz",
        stat=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.lca.stat.gz",
        flag=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.lca.done"
    log:
        BASE + "/aeDNA_{age}/threeDB/{db}/logs/{sample}.metaDMG_lca.log"
    wildcard_constraints:
        age="morden|young|old|deeptime",
        db="DB1_standard|DB2_plus_truth|DB3_minus_truth"
    params:
        temp=lambda wc: f"{BASE}/aeDNA_{wc.age}/threeDB/{wc.db}/metaDMG_temp/{wc.sample}",
        prefix=lambda wc: f"{BASE}/aeDNA_{wc.age}/threeDB/{wc.db}/metaDMG/{wc.sample}/{wc.sample}.metaDMG.lca"
    threads:
        20
    resources:
        mem_mb=60000
    shell:
        r"""
        set -euo pipefail

        mkdir -p "$(dirname "{output.flag}")"
        mkdir -p "$(dirname "{log}")"
        rm -rf "{params.temp}"
        mkdir -p "{params.temp}"

        echo "===== START LCA =====" > "{log}"
        date >> "{log}"
        echo "age={wildcards.age}" >> "{log}"
        echo "db={wildcards.db}" >> "{log}"
        echo "sample={wildcards.sample}" >> "{log}"
        echo "BAM={input.bam}" >> "{log}"
        echo "ACC2TAX={input.acc2tax}" >> "{log}"

        file "{input.bam}" >> "{log}" 2>&1
        samtools quickcheck -v "{input.bam}" >> "{log}" 2>&1

        metaDMG-cpp lca \
            --threads {threads} \
            --bam "{input.bam}" \
            --nodes "{input.nodes}" \
            --names "{input.names}" \
            --acc2tax "{input.acc2tax}" \
            --fix_ncbi 0 \
            --how_many 15 \
            --sim_score_low 0.95 \
            --weight_type 0 \
            --lca_rank genus \
            --temp "{params.temp}" \
            --out_prefix "{params.prefix}" \
            >> "{log}" 2>&1

        touch "{output.flag}"
        echo "===== SUCCESS LCA =====" >> "{log}"
        date >> "{log}"
        """


rule metaDMG_damage:
    input:
        bam=rules.merge_compact_bam.output.bam
    output:
        flag=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.damage.done"
    log:
        BASE + "/aeDNA_{age}/threeDB/{db}/logs/{sample}.metaDMG_damage.log"
    wildcard_constraints:
        age="young|old|deeptime",
        db="DB1_standard|DB2_plus_truth|DB3_minus_truth"
    params:
        prefix=lambda wc: f"{BASE}/aeDNA_{wc.age}/threeDB/{wc.db}/metaDMG/{wc.sample}/{wc.sample}.metaDMG.dmg"
    threads:
        10
    resources:
        mem_mb=40000
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname "{output.flag}")"
        mkdir -p "$(dirname "{log}")"

        echo "===== START DAMAGE =====" > "{log}"
        date >> "{log}"

        metaDMG-cpp getdamage \
            --run_mode 0 \
            --print_length 15 \
            --min_length 30 \
            --out_prefix "{params.prefix}" \
            "{input.bam}" \
            >> "{log}" 2>&1

        touch "{output.flag}"
        echo "===== SUCCESS DAMAGE =====" >> "{log}"
        date >> "{log}"
        """


rule metaDMG_dfit:
    input:
        bdamage=rules.metaDMG_lca.output.bdamage,
        nodes=NODES,
        names=NAMES
    output:
        dfit=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.dfit.dfit.gz",
        flag=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.dfit.done"
    log:
        BASE + "/aeDNA_{age}/threeDB/{db}/logs/{sample}.metaDMG_dfit.log"
    wildcard_constraints:
        age="young|old|deeptime",
        db="DB1_standard|DB2_plus_truth|DB3_minus_truth"
    params:
        prefix=lambda wc: f"{BASE}/aeDNA_{wc.age}/threeDB/{wc.db}/metaDMG/{wc.sample}/{wc.sample}.metaDMG.dfit"
    threads:
        20
    resources:
        mem_mb=40000
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname "{log}")"

        echo "===== START DFIT =====" > "{log}"
        date >> "{log}"

        metaDMG-cpp dfit \
            "{input.bdamage}" \
            --threads {threads} \
            --nodes "{input.nodes}" \
            --names "{input.names}" \
            --nopt 5 \
            --showfits 2 \
            --seed 42 \
            --out_prefix "{params.prefix}" \
            >> "{log}" 2>&1

        touch "{output.flag}"
        echo "===== SUCCESS DFIT =====" >> "{log}"
        date >> "{log}"
        """


rule metaDMG_aggregate:
    input:
        damage_flag=rules.metaDMG_damage.output.flag,
        lca_flag=rules.metaDMG_lca.output.flag,
        dfit_flag=rules.metaDMG_dfit.output.flag,
        bdamage=rules.metaDMG_lca.output.bdamage,
        lcastat=rules.metaDMG_lca.output.stat,
        dfit=rules.metaDMG_dfit.output.dfit,
        nodes=NODES,
        names=NAMES
    output:
        flag=BASE + "/aeDNA_{age}/threeDB/{db}/metaDMG/{sample}/{sample}.metaDMG.aggregate.done"
    log:
        BASE + "/aeDNA_{age}/threeDB/{db}/logs/{sample}.metaDMG_aggregate.log"
    wildcard_constraints:
        age="young|old|deeptime",
        db="DB1_standard|DB2_plus_truth|DB3_minus_truth"
    params:
        out=lambda wc: f"{BASE}/aeDNA_{wc.age}/threeDB/{wc.db}/metaDMG/{wc.sample}/{wc.sample}.metaDMG.aggregate"
    threads:
        10
    resources:
        mem_mb=40000
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname "{log}")"

        echo "===== START AGGREGATE =====" > "{log}"
        date >> "{log}"

        metaDMG-cpp aggregate \
            "{input.bdamage}" \
            --dfit "{input.dfit}" \
            --lcastat "{input.lcastat}" \
            --nodes "{input.nodes}" \
            --names "{input.names}" \
            --out "{params.out}" \
            >> "{log}" 2>&1

        touch "{output.flag}"
        echo "===== SUCCESS AGGREGATE =====" >> "{log}"
        date >> "{log}"
        """
