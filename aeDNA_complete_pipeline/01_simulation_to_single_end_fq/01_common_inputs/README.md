# Shared simulation inputs

This directory contains the empirical inputs and NCBI assembly summaries used by Stage 1. Simulation scripts resolve it relative to their own location, so these files no longer require `/online1/...` paths. Set `COMMON_INPUTS_DIR` only when storing inputs elsewhere.

## Included empirical profiles

| Path | Used by |
|---|---|
| `fragmentation/modern_len_dis.txt` | Modern FragSim runs |
| `fragmentation/young_len_dis.txt` | Young FragSim runs |
| `fragmentation/old_len_dis.txt` | Old FragSim runs |
| `fragmentation/veryold_len_dis.txt` | Deep-time FragSim runs |
| `Damage/young_misincorporation.txt` | Young deamSim run |
| `Damage/old_misincorporation.txt` | Old deamSim run |
| `Damage/veryold_misincorporation.txt` | Deep-time deamSim run |

Use the original `veryold_misincorporation.txt`, not `veryold_misincorporation_paired.txt`.

## Included assembly summaries

| File | Category | Truth600 accessions expected |
|---|---|---:|
| `refgenome/a_assembly_summary.txt` | Archaea | part of 500 microbial genomes |
| `refgenome/b_assembly_summary.txt` | Bacteria | part of 500 microbial genomes |
| `refgenome/f_assembly_summary.txt` | Fungi | part of 500 microbial genomes |
| `refgenome/i_assembly_summary.txt` | Invertebrates | part of 50 animal genomes |
| `refgenome/vm_assembly_summary.txt` | Vertebrate mammals | part of 50 animal genomes |
| `refgenome/vo_assembly_summary.txt` | Other vertebrates | part of 50 animal genomes |
| `refgenome/p_assembly_summary.txt` | Plants | 50 plant genomes |

These seven files resolve all 500 microbial, 50 animal, and 50 plant accessions in the supplied lists.

### Completeness

All category-specific assembly summaries needed by the supplied accession lists are now present in this directory. `prepare_reference_genomes.sh manifest` validates that every summary is non-empty and reports unresolved accessions for each biological group. `PLANT_SUMMARY` may still be set when intentionally using a different plant snapshot.

Also preserve or supply a final Truth600 accession/taxid/category/nuclear-organelle manifest and per-age/per-replicate random seeds, realized abundances, and requested read counts. Assembly summaries resolve downloads but do not replace the biological truth manifest.

```bash
COMMON_INPUTS_DIR=/path/to/common_inputs \
PLANT_SUMMARY=/path/to/p_assembly_summary.txt \
WORK_ROOT=/path/to/reference_workspace \
  bash ../00_reference_download/prepare_reference_genomes.sh all
```

Store checksums and retrieval dates. `b_assembly_summary.txt` is approximately 77 MB; GitHub accepts files below 100 MB but warns above 50 MB, so consider Git LFS or a documented compressed/archive download for long-term distribution.
