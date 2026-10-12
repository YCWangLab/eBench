# Reproducibility checklist

## Before running

- [ ] Confirm all seven biological categories and totals (351/99/50/50/15/15/20), plus their three execution groups (micro 500, animals 50, plants 50).
- [ ] Archive assembly summaries, accession lists and downloaded FASTA checksums.
- [ ] Replace every executable `/online1/...` path.
- [ ] Use one dated, compatible NCBI taxonomy/index snapshot.
- [ ] Record all software versions.
- [ ] Run `python scripts/preflight.py` and every Snakemake dry-run.

## During the workflow

- [ ] Record seeds or complete realized random/abundance tables.
- [ ] Retain 30 replicates for each of four ages.
- [ ] Verify organellar ratios, single-end counts and truth-bearing read headers.
- [ ] Save stdout, stderr and scheduler metadata.
- [ ] Review accession/taxid and DB3 overlap audits.
- [ ] Inspect metaDMG fit diagnostics.

## Publication package

- [ ] Tagged code release and DOI archive.
- [ ] Methods/parameter table matching scripts.
- [ ] Truth600 manifest, taxonomy identifiers and checksums.
- [ ] Environment export and command log.
- [ ] Per-replicate abundance/count table and seeds.
- [ ] Checksums for final FASTQ, BAM and result tables.
- [ ] Software/data citations and licences.
