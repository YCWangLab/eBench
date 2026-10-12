# Reference-genome preparation

## Optional reproducible random selection

The biological design has seven independently sampled categories, subsequently combined into three execution lists. The three bundled accession files are the already-realized selection used by the completed downstream work and remain the default.

To generate a new panel following the original random row-selection idea, but with a recorded seed and eligibility checks:

```bash
bash prepare_reference_genomes.sh select 20261012
SELECTED_LIST_DIR="$PWD/work/selection" bash prepare_reference_genomes.sh all
```

Replace the example seed with the run seed. `select_truth600.py` draws 351 bacteria, 99 archaea, 50 fungi, 50 plants, 15 mammals, 15 other vertebrates and 20 invertebrates from summary records that contain both an accession and usable FTP path. It writes seven category lists, three merged lists, accession/FTP tables, summary SHA-256 values and `selection_manifest.json`. It never overwrites the bundled realized selection. A different seed creates a different Truth600 panel.

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
| `SELECTED_LIST_DIR` | directory containing the three bundled realized lists |

```bash
COMMON_INPUTS_DIR=/path/to/common_inputs \
SUMMARY_DIR=/path/to/assembly_summaries \
PLANT_SUMMARY=/path/to/p_assembly_summary.txt \
WORK_ROOT=/path/to/reference_workspace \
  bash prepare_reference_genomes.sh all
```

Expected files are `a_`, `b_`, and `f_assembly_summary.txt` for microbes; `i_`, `vm_`, and `vo_assembly_summary.txt` for animals; and `p_assembly_summary.txt` for plants. All seven are now included under `01_common_inputs/refgenome/`. Use `SUMMARY_DIR` or `PLANT_SUMMARY` only to select a different local snapshot.

Dependencies: Bash, `awk`, `sort`, `comm`, `wget`, `gzip`, and `seqkit`. Inspect every `manifests/*.unresolved.txt`. Generated downloads and split references under `work/` are excluded from Git.
