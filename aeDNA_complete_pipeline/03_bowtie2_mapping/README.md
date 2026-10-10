# Stage 3: Bowtie2 mapping and logical databases

Repeat for `morden`, `young`, `old`, and `deeptime` after changing `BASE` and index paths.

```bash
snakemake -s original_snakemake_aeDNA_mapping.ver1.250815.smk --config age=young -n -p
snakemake -s 01_truth600_mapping.smk --config age=young -n -p
snakemake -s 04_check_overlap_before_DB3.smk --config age=young -j 20 -p
snakemake -s 02_DB2_plus_truth_collection.smk --config age=young -j 20 -p
snakemake -s 03_DB3_minus_truth_filter.smk --config age=young -j 40 -p
```

All rules use single-end `-U` with `-k 100 -L 22 -i S,1,1.15 --mp 1,1 --rdg 0,1 --rfg 0,1 --score-min L,0,-0.1 --no-unal`. Outputs are query-name-sorted binary BAMs checked by samtools.

DB2 collects independent Standard and Truth600 mappings. DB3 removes Truth600 references from Standard candidates. If the overlap report is near zero, reconcile accession/header conventions before DB3.
