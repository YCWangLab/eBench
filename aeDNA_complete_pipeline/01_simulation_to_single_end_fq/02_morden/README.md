# Modern baseline (`morden`)

```bash
snakemake -s Snakefile -n -p
snakemake -s Snakefile -j 1 -p
```

1. `atxt.sh` generates per-taxon counts (10–10,000) for 30 replicates.
2. `addmicroreads.sh`, `addanimalsreads.sh`, and `addplantsreads.sh` run FragSim with the modern length distribution.
3. `mergemorden.sh` combines nuclear and organellar components.
4. `speciesmerge.sh` combines microbial, animal, and plant sequences.
5. `05_fasta_to_single_end_fastq.sh` writes one FASTQ per sample.

No mutation or deamination is added, making this the negative control. Reconcile the `.../ycwang/...` and `.../liuz/...` roots. Save the output of `atxt.sh` or use a seeded replacement for exact reproducibility.
