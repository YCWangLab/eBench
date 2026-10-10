# Stage 1: simulate single-end FASTQ

This stage prepares reference genomes and simulates four scenarios. Length distributions, damage profiles, and assembly summaries are stored in `01_common_inputs/`. Fragmentation scripts use references generated under `00_reference_download/work/split_genomes/` by default.

| Directory | Scenario | Mutation | Damage |
|---|---|---|---|
| `02_morden/` | modern baseline | none | none |
| `03_young/` | young | class-specific | young profile |
| `04_old/` | old | class-specific | old profile |
| `05_deeptime/` | deep time | class-specific | very-old profile |

```bash
snakemake -s 02_morden/Snakefile -n -p
snakemake -s 03_young/Snakefile -n -p
snakemake -s 04_old/Snakefile -n -p
snakemake -s 05_deeptime/Snakefile -n -p
```

Each sample ends in one `.fq`; downstream Bowtie2 uses `-U`. In Gargammel, `double` describes the double-stranded-library damage model, not paired-end reads. Set `COMMON_INPUTS_DIR` or `REFERENCE_ROOT` to override the portable defaults. Preserve read-count tables and random seeds.
