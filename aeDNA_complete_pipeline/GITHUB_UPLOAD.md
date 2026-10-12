# GitHub upload guide

This directory is self-contained and can be uploaded as the repository root. No GitHub changes are performed by the preparation workflow.

## 1. Review locally

```bash
cd /path/to/aeDNA_complete_pipeline
python scripts/preflight.py
git status --short
```

Review `README.md`, `METHODS.md`, `docs/`, all stage READMEs and the executable files. Replace site-specific paths only when the target HPC layout is known. Do not commit FASTQ, BAM, downloaded FASTA, Bowtie2 indexes, secrets or scheduler logs.

The bacterial assembly summary is large but below GitHub's 100 MB per-file hard limit. GitHub may still display a large-file warning. For a long-term paper release, Git LFS or a DOI-backed archive can be used, provided the README gives a public download link and SHA-256 checksum.

## 2. Create or update a repository

For a new repository:

```bash
git init
git branch -M main
git add .
git status --short
git diff --cached --stat
git commit -m "Add reproducible aeDNA benchmark pipeline"
git remote add origin https://github.com/YOUR_ACCOUNT/YOUR_REPOSITORY.git
git remote -v
git push -u origin main
```

For the existing `YCWangLab/eBench` checkout, copy or replace only the `aeDNA_complete_pipeline/` directory inside that checkout, then inspect the diff before committing:

```bash
git status --short
git diff -- aeDNA_complete_pipeline
git add aeDNA_complete_pipeline
git diff --cached --stat
git commit -m "Complete reproducible aeDNA simulation pipeline"
git push
```

Always verify the account and repository shown by `git remote -v` before pushing. Never place a personal access token in a script, README or remote URL.

## 3. Verify after upload

- Confirm that the main README and all figures render correctly.
- Confirm that all 11 stage/root READMEs are present.
- Confirm that the seven summaries, three realized accession lists and empirical profiles are present.
- Confirm that generated FASTQ/BAM/reference/index files were not uploaded.
- Run the preflight from a fresh clone.
- Create a version tag and archive the reviewed release with a DOI for publication.
