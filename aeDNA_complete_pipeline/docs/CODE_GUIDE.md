# Code guide

This guide explains every executable or workflow file in the repository. Files are grouped in execution order. Scientific parameters are documented in `METHODS.md`; paths requiring adaptation are documented in `docs/PATHS_AND_CONFIGURATION.md`.

## Repository-level support files

| File | Purpose |
|---|---|
| `scripts/preflight.py` | Checks bundled empirical inputs, all three realized accession lists, the seven category counts, assembly summaries and unresolved HPC paths before execution. |
| `environment.yml` | Defines the Conda software environment for Snakemake, Bowtie2, SAMtools, SeqKit, BBMap, Java and metaDMG. Gargammel and Mutation-Simulator are documented as separate installations. |
| `.gitattributes` | Forces LF line endings for Linux/HPC scripts and consistent text handling by Git. |
| `.gitignore` | Prevents generated reads, alignments, references, indexes, logs, caches and local secrets from being committed. |
| `PIPELINE_MANIFEST.tsv` | Machine-readable list of the principal workflow entry points. |

## Stage 1A: select and prepare the 600 references

Directory: `01_simulation_to_single_end_fq/00_reference_download/`

| File | Purpose |
|---|---|
| `select_truth600.py` | Reproducibly samples 351 bacteria, 99 archaea, 50 fungi, 50 plants, 15 mammals, 15 other vertebrates and 20 invertebrates from the seven assembly summaries using a recorded seed. It writes seven category lists, three merged execution lists and an audit manifest. |
| `prepare_reference_genomes.sh` | Resolves the selected accessions to FTP locations, reports unresolved accessions, downloads/decompresses genomes, and separates animal and plant nuclear/organellar sequences. It can use either the bundled realized lists or a newly seeded selection. |

The three `accession_*_list.txt` files are data inputs, not programs. They are the realized 600-genome selection used by the existing downstream simulation.

## Stage 1B: modern simulation

Directory: `01_simulation_to_single_end_fq/02_morden/`. The historical word `morden` means modern.

| File | Purpose |
|---|---|
| `Snakefile` | Runs modern abundance generation, fragmentation, component merging and FASTQ conversion in order. |
| `workflow/scripts/atxt.sh` | Generates 30 replicate microbial abundance/count vectors, with one value from 10--10,000 per microbial genome. |
| `workflow/scripts/addmicroreads.sh` | Uses FragSim and the modern length profile to produce microbial fragments. |
| `workflow/scripts/addanimalsreads.sh` | Produces animal nuclear and mitochondrial fragments and applies the 100:1 contribution rule. |
| `workflow/scripts/addplantsreads.sh` | Produces plant nuclear, chloroplast and mitochondrial fragments and applies the 50:50:1 rule. |
| `workflow/scripts/mergemorden.sh` | Merges animal nuclear/mitochondrial and plant nuclear/chloroplast/mitochondrial components for each replicate. |
| `workflow/scripts/speciesmerge.sh` | Merges microbial, animal and plant components into each modern community. |
| `workflow/scripts/05_fasta_to_single_end_fastq.sh` | Converts final modern FASTA fragments into single-end FASTQ with BBMap `reformat.sh`. |

## Stage 1C: young simulation

Directory: `01_simulation_to_single_end_fq/03_young/`.

| File | Purpose |
|---|---|
| `Snakefile` | Runs young fragmentation, substitutions, merging, empirical damage and FASTQ conversion. |
| `workflow/scripts/addymicroreads.sh` | Produces young microbial fragments using the young length profile. |
| `workflow/scripts/addyanimalsreads.sh` | Produces young animal nuclear and mitochondrial fragments with the animal ratio. |
| `workflow/scripts/addyplantsreads.sh` | Produces young plant nuclear, chloroplast and mitochondrial fragments with the plant ratio. |
| `workflow/scripts/mutationyoung.sh` | Applies young age- and genome-component-specific substitution fractions with Mutation-Simulator. |
| `workflow/scripts/04_merge_animal_plant.sh` | Recombines mutated nuclear and organellar components into animal and plant fractions. |
| `workflow/scripts/05_merge_all_sources.sh` | Merges microbial, animal and plant fractions into complete young communities. |
| `workflow/scripts/06_damage_young.sh` | Applies the empirical young misincorporation profile with Gargammel deamSim. |
| `workflow/scripts/06_fasta_to_single_end_fastq.sh` | Converts damaged young FASTA files to single-end FASTQ. |

## Stage 1D: old simulation

Directory: `01_simulation_to_single_end_fq/04_old/`.

| File | Purpose |
|---|---|
| `Snakefile` | Runs old fragmentation, substitutions, merging, damage and FASTQ conversion. |
| `workflow/scripts/addoldreads.sh` | Produces microbial, animal and plant fragments using the old length profile and organellar ratios. |
| `workflow/scripts/mutationold.sh` | Applies old age- and component-specific substitution fractions. |
| `workflow/scripts/03_merge_animal_plant.sh` | Recombines old animal and plant nuclear/organellar components. |
| `workflow/scripts/04_merge_all_sources.sh` | Merges all old community fractions. |
| `workflow/scripts/03_damage_old.sh` | Applies the empirical old misincorporation profile. |
| `workflow/scripts/04_fasta_to_single_end_fastq.sh` | Converts damaged old FASTA files to single-end FASTQ. |

## Stage 1E: deep-time simulation

Directory: `01_simulation_to_single_end_fq/05_deeptime/`.

| File | Purpose |
|---|---|
| `Snakefile` | Runs deep-time fragmentation, substitutions, merging, damage and FASTQ conversion. |
| `workflow/scripts/adddeepreads.sh` | Produces microbial, animal and plant fragments using the deep-time length profile and organellar ratios. |
| `workflow/scripts/mutationdeep.sh` | Applies deep-time age- and component-specific substitution fractions. |
| `workflow/scripts/03_merge_animal_plant.sh` | Recombines deep-time animal and plant nuclear/organellar components. |
| `workflow/scripts/03_merge_all_sources.sh` | Merges all deep-time community fractions. |
| `workflow/scripts/04_damage_deeptime.sh` | Applies the empirical deep-time misincorporation profile. |
| `workflow/scripts/05_fasta_to_single_end_fastq.sh` | Converts damaged deep-time FASTA files to single-end FASTQ. |

## Stage 2: taxonomy and database preparation

Directory: `02_three_database_preparation/`.

| File | Purpose |
|---|---|
| `00_make_truth_id_list.smk` | Extracts exact and version-stripped identifiers for the Truth600 references for matching and exclusion. |
| `01_prepare_DB2_acc2tax.smk` | Coordinates creation and audit of the combined Standard + Truth600 accession-to-taxid mapping used for DB2. |
| `scripts/build_db2_acc2tax.py` | Combines Standard and Truth600 accession mappings, normalizes accessions, checks conflicts and writes audit results. |

## Stage 3: mapping and three logical databases

Directory: `03_bowtie2_mapping/`.

| File | Purpose |
|---|---|
| `original_snakemake_aeDNA_mapping.ver1.250815.smk` | Performs DB1 mapping against the Standard `nt+ref` indexes. Despite its historical filename, this is an active required entry point. |
| `01_truth600_mapping.smk` | Maps the same single-end reads independently against the Truth600 index. |
| `04_check_overlap_before_DB3.smk` | Audits identifier overlap before Truth600 accessions are excluded for DB3. |
| `02_DB2_plus_truth_collection.smk` | Combines Standard and Truth600 alignment candidates to form logical DB2. |
| `03_DB3_minus_truth_filter.smk` | Removes Truth600 accessions from Standard candidates to form logical DB3. |

## Stage 4: merge, LCA and damage estimation

Directory: `04_merge_lca_metaDMG/`.

| File | Purpose |
|---|---|
| `02_merge_metaDMG_all4_3DB.smk` | Runs candidate merging, query-name sorting, LCA assignment, damage extraction, model fitting and aggregation across four ages and three database conditions. |
| `scripts/merge_compact_bam.py` | Streams legacy SAM/BAM/CRAM shards, preserves required alignments and creates a compact merged alignment input for downstream LCA processing. |

## Input files that are not code

- `01_common_inputs/refgenome/*_assembly_summary.txt`: the seven NCBI assembly-summary snapshots used for selection and accession resolution.
- `01_common_inputs/fragmentation/*.txt`: empirical fragment-length distributions.
- `01_common_inputs/Damage/*.txt`: empirical terminal misincorporation profiles.
- `docs/figures/*.png`: figures used directly by the root README and Methods.

No executable file in this guide is an unused legacy copy. Deleting one removes a documented workflow function.
