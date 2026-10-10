# Deep-time scenario

```bash
snakemake -s Snakefile -n -p
snakemake -s Snakefile -j 1 -p
```

The workflow fragments with `veryold_len_dis.txt`; applies substitution rates 0.04 (microbial), 0.004 (animal/plant nuclear), and 0.08 (animal/plant organellar), all with transition/transversion ratio 1; merges sources; applies the original `veryold_misincorporation.txt`; and writes one single-end `.fq` per replicate.

Do not substitute `veryold_misincorporation_paired.txt`. Replace all HPC paths before running.
