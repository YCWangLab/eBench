# Young scenario

```bash
snakemake -s Snakefile -n -p
snakemake -s Snakefile -j 1 -p
```

The workflow fragments reads with the young length profile; runs `mutationyoung.sh` with substitution rates 0.0001 (microbial), 0.00001 (animal/plant nuclear), and 0.0002 (animal/plant organellar), all with transition/transversion ratio 1; merges all sources; applies `young_misincorporation.txt`; and writes one single-end `.fq` per replicate.

Replace hard-coded data, profile, tool, and output paths before execution. The deamSim `double` setting is a double-stranded-library model, not paired-end output.
