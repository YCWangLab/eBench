# Old scenario

```bash
snakemake -s Snakefile -n -p
snakemake -s Snakefile -j 1 -p
```

The Snakefile runs `addoldreads.sh`; `mutationold.sh` with substitution rates 0.001 (microbial), 0.0001 (animal/plant nuclear), and 0.002 (animal/plant organellar), all with transition/transversion ratio 1; `03_merge_animal_plant.sh`; `04_merge_all_sources.sh`; `03_damage_old.sh` with `old_misincorporation.txt`; and `04_fasta_to_single_end_fastq.sh`.

The numeric prefixes are historical; the Snakefile defines execution order. Check rates in `mutationold.sh` against Table 2 in `aeDNA_gauge-main`, replace site-specific paths, and preserve seeds and abundance tables. Output is one single-end `.fq` per replicate.
