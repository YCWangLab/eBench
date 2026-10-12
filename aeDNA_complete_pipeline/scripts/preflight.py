#!/usr/bin/env python3
"""Static, data-light audit for the aeDNA benchmark source tree."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
COMMON = ROOT / "01_simulation_to_single_end_fq" / "01_common_inputs"
DOWNLOAD = ROOT / "01_simulation_to_single_end_fq" / "00_reference_download"
EXPECTED = {
    "accession_aemicros_list.txt": 500,
    "accession_aeanimals_list.txt": 50,
    "accession_aeplants_list.txt": 50,
}
SUMMARIES = [f"{key}_assembly_summary.txt" for key in ("a", "b", "f", "i", "p", "vm", "vo")]
CATEGORY_EXPECTED = {"b": 351, "a": 99, "f": 50, "p": 50, "vm": 15, "vo": 15, "i": 20}
CATEGORY_GROUP = {"b": "accession_aemicros_list.txt", "a": "accession_aemicros_list.txt",
                  "f": "accession_aemicros_list.txt", "p": "accession_aeplants_list.txt",
                  "vm": "accession_aeanimals_list.txt", "vo": "accession_aeanimals_list.txt",
                  "i": "accession_aeanimals_list.txt"}

def rows(path):
    with path.open(encoding="utf-8", errors="replace") as handle:
        return sum(1 for line in handle if line.strip() and not line.startswith("#"))

def first_column(path):
    with path.open(encoding="utf-8", errors="replace") as handle:
        return {line.split("\t", 1)[0].strip() for line in handle
                if line.strip() and not line.startswith("#")}

def main():
    errors, warnings, counts = [], [], {}
    required = [
        "fragmentation/modern_len_dis.txt", "fragmentation/young_len_dis.txt",
        "fragmentation/old_len_dis.txt", "fragmentation/veryold_len_dis.txt",
        "Damage/young_misincorporation.txt", "Damage/old_misincorporation.txt",
        "Damage/veryold_misincorporation.txt"]
    for rel in required:
        path = COMMON / rel
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing/empty: {path.relative_to(ROOT)}")
    for name, expected in EXPECTED.items():
        acc = DOWNLOAD / name
        if acc.is_file():
            counts[name] = rows(acc)
            if counts[name] != expected:
                errors.append(f"{name} has {counts[name]}; expected {expected}")
        else:
            errors.append(f"missing: {acc.relative_to(ROOT)}")
    for name in SUMMARIES:
        summary = COMMON / "refgenome" / name
        if not summary.is_file() or summary.stat().st_size == 0:
            errors.append(f"missing/empty: {summary.relative_to(ROOT)}")
    category_counts = {}
    for category, expected in CATEGORY_EXPECTED.items():
        summary = COMMON / "refgenome" / f"{category}_assembly_summary.txt"
        group = DOWNLOAD / CATEGORY_GROUP[category]
        if summary.is_file() and group.is_file():
            category_counts[category] = len(first_column(summary) & first_column(group))
            if category_counts[category] != expected:
                warnings.append(
                    f"current summary classifies {category}={category_counts[category]}; "
                    f"design target={expected}. Preserve the design label and review metadata."
                )
    site_files = [p for p in ROOT.rglob("*") if p.suffix in {".sh", ".smk"}
                  and p.is_file() and "/online1/" in p.read_text(errors="replace")]
    if site_files:
        warnings.append(f"{len(site_files)} scripts retain /online1 paths; configure per docs/PATHS_AND_CONFIGURATION.md")
    print("aeDNA source-tree preflight")
    print("accessions: " + ", ".join(f"{k}={counts.get(k, 0)}" for k in EXPECTED))
    print("seven categories resolved against bundled summaries: " + ", ".join(
        f"{k}={category_counts.get(k, 0)}" for k in CATEGORY_EXPECTED))
    for msg in warnings: print("WARNING:", msg)
    for msg in errors: print("ERROR:", msg)
    print(("FAIL" if errors else "PASS") + f": {len(errors)} error(s), {len(warnings)} warning(s)")
    return bool(errors)

if __name__ == "__main__":
    sys.exit(main())
