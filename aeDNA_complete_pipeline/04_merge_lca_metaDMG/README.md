# Stage 4: merge, LCA, and metaDMG

```bash
snakemake -s 02_merge_metaDMG_all4_3DB.smk -n -p
snakemake -s 02_merge_metaDMG_all4_3DB.smk -j 20 -p
```

```text
alignment shards → merge_compact_bam.py → name-sorted BAM → lca → getdamage → dfit → aggregate
```

`merge_compact_bam.py` accepts legacy SAM text, BAM, or CRAM. `morden` runs through LCA; ancient scenarios run the full damage chain. Keep modern as the no-damage control.

Replace `BASE`, `NODES`, `NAMES`, accession-to-taxid and executable paths, and scheduler resources. Taxonomy inputs must be compatible. Ancient alignments are currently filtered to sequence length below 200 bp; account for that filter in age comparisons or also retain unfiltered classifications.
