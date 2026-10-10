# Stage 2: database and taxonomy preparation

```bash
snakemake -s 00_make_truth_id_list.smk -j 1 -p
snakemake -s 01_prepare_DB2_acc2tax.smk -j 1 -p
```

The first workflow extracts exact and version-stripped Truth600 IDs. The second calls `scripts/build_db2_acc2tax.py` to combine taxonomy mappings.

For accession conflicts, the Standard taxid wins to remain compatible with the Standard taxonomy snapshot; conflicts are still reported. Truth-only taxids are appended only if present in `nodes.dmp`. Require `appended_truth_taxids_missing_from_nodes = 0` before Stage 4.

Change `BASE`, `STANDARD_ACC2TAX`, `TRUTH_ACC2TAX`, `NODES`, and `OUTDIR`. This stage does not build physical combined/subtracted indexes.
