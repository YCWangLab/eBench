# Paths and configuration

The workflow retains scientific parameters from the original HPC implementation. Adapt these site paths before execution.

| Original path or variable | Meaning | Replace with |
|---|---|---|
| `/online1/ycsc_wx/ycwang/aeDNA/<age>` | simulation workspace | writable per-age work directory |
| `/online1/ycsc_wx/liuz/srq/aeDNA_db/aeDNA_database` | shared `BASE` | analysis root expected by the Snakefiles |
| `/online1/ycsc_wx/liuz/database/NCBI_2401` | Standard indexes/taxonomy | local, mutually compatible database snapshot |
| `.../gargammel/bin/fragSim` | fragment simulator | local executable |
| `.../gargammel/bin/deamSim` | damage simulator | local executable |
| `.../bbmap/reformat.sh` | FASTA-to-FASTQ converter | local executable |
| `COMMON_INPUTS_DIR` | empirical inputs | normally leave unset; bundled inputs resolve automatically |
| `REFERENCE_ROOT` | prepared FASTA root | set only if references live elsewhere |

Locate executable occurrences with:

```bash
grep -RIn --include='*.sh' --include='*.smk' '/online1/' .
```

Edit assignments near script/Snakefile beginnings. Do not blindly replace documentation or provenance text. Keep historical `morden` unless every dependent path changes together.

The Standard accession mapping, Truth600 mapping, `nodes.dmp`, `names.dmp`, indexes and manifest must use a compatible NCBI snapshot. Treat missing/conflicting taxids as errors. Change SLURM partition, account, resources and logs for the target cluster; these are not scientific parameters.

Recommended layout:

```text
project/code
project/references
project/taxonomy/YYYY-MM-DD
project/work
project/results
project/logs
```
