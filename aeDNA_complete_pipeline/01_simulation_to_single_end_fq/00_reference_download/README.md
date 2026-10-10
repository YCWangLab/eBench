# Reference-genome preparation

`prepare_reference_genomes.sh` resolves the Truth600 accession lists against summaries in `../01_common_inputs/refgenome/`, writes audit manifests, downloads/decompresses genomic FASTA, and separates animal and plant nuclear/organellar sequences.

```bash
bash prepare_reference_genomes.sh manifest
bash prepare_reference_genomes.sh download
bash prepare_reference_genomes.sh split
bash prepare_reference_genomes.sh all
```

| Variable | Default |
|---|---|
| `COMMON_INPUTS_DIR` | `../01_common_inputs` |
| `SUMMARY_DIR` | `$COMMON_INPUTS_DIR/refgenome` |
| `WORK_ROOT` | `./work` |
| `PLANT_SUMMARY` | `$SUMMARY_DIR/p_assembly_summary.txt` |

```bash
COMMON_INPUTS_DIR=/path/to/common_inputs \
SUMMARY_DIR=/path/to/assembly_summaries \
PLANT_SUMMARY=/path/to/p_assembly_summary.txt \
WORK_ROOT=/path/to/reference_workspace \
  bash prepare_reference_genomes.sh all
```

Expected files are `a_`, `b_`, and `f_assembly_summary.txt` for microbes; `i_`, `vm_`, and `vo_assembly_summary.txt` for animals; and `p_assembly_summary.txt` for plants. All seven are now included under `01_common_inputs/refgenome/`. Use `SUMMARY_DIR` or `PLANT_SUMMARY` only to select a different local snapshot.

Dependencies: Bash, `awk`, `sort`, `comm`, `wget`, `gzip`, and `seqkit`. Inspect every `manifests/*.unresolved.txt`. Generated downloads and split references under `work/` are excluded from Git.
