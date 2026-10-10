STANDARD_ACC2TAX = "/online1/ycsc_wx/liuz/database/NCBI_2401/taxonomy/nucl_gb_acc2tax_202401"
TRUTH_ACC2TAX = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/genomes/aeDNA_acc2taxid/acc2taxid_temp/all_aeDNA.acc2taxid"
NODES = "/online1/ycsc_wx/liuz/database/NCBI_2401/taxonomy/dmp/nodes.dmp"
OUTDIR = "/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database/genomes/aeDNA_acc2taxid/threeDB"

rule all:
    input:
        OUTDIR + "/DB2_standard_plus_truth.acc2taxid",
        OUTDIR + "/DB2_standard_plus_truth.conflicts.tsv",
        OUTDIR + "/DB2_standard_plus_truth.summary.tsv",
        OUTDIR + "/DB2_standard_plus_truth.invalid_truth_taxids.tsv"

rule build_db2_acc2tax:
    input:
        standard = STANDARD_ACC2TAX,
        truth = TRUTH_ACC2TAX,
        nodes = NODES
    output:
        combined = OUTDIR + "/DB2_standard_plus_truth.acc2taxid",
        conflicts = OUTDIR + "/DB2_standard_plus_truth.conflicts.tsv",
        summary = OUTDIR + "/DB2_standard_plus_truth.summary.tsv",
        invalid = OUTDIR + "/DB2_standard_plus_truth.invalid_truth_taxids.tsv"
    resources:
        mem_mb = 40000,
        time_hours = 4
    threads: 1
    shell:
        r"""
        set -euo pipefail
        mkdir -p {OUTDIR}
        python scripts/build_db2_acc2tax.py \
          --standard {input.standard} \
          --truth {input.truth} \
          --nodes {input.nodes} \
          --output {output.combined} \
          --conflicts {output.conflicts} \
          --summary {output.summary} \
          --invalid-truth-taxids {output.invalid}
        """
