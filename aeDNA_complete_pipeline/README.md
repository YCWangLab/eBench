# Complete aeDNA three-database pipeline

This is the recommended integrated workflow. It produces single-end simulated aeDNA reads and evaluates three logical database conditions.

```text
01 simulation and FASTQ → 02 taxonomy preparation → 03 mapping → 04 LCA and metaDMG
```

| Stage | Directory | Main outputs |
|---|---|---|
| 1 | `01_simulation_to_single_end_fq/` | One `<sample>.fq` per age and replicate |
| 2 | `02_three_database_preparation/` | Truth600 IDs, combined DB2 acc2tax, audits |
| 3 | `03_bowtie2_mapping/` | Standard/Truth600 BAMs, DB2 collection, DB3 BAMs |
| 4 | `04_merge_lca_metaDMG/` | Merged BAM, LCA, bdamage, dfit, aggregate |

See each stage README and `PIPELINE_MANIFEST.tsv` for entry points.

DB1 is existing Standard `nt+ref`. DB2 combines independently generated Standard and Truth600 candidates before LCA. DB3 removes Truth600 hits from Standard candidates. DB2/DB3 do not physically rebuild `nt+ref±Truth600` indexes.

Empirical length/damage profiles and all seven category-specific assembly summaries are bundled under `01_simulation_to_single_end_fq/01_common_inputs/`. Before running: provide the final Truth600 manifest; replace remaining `/online1/...` output/tool/index paths; use one compatible taxonomy snapshot; adjust SLURM resources; save seeds and realized abundances; dry-run every Snakefile; and review all audit outputs. The historical path label `morden` means modern.
