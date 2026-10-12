#!/usr/bin/env python3
"""Reproducibly select seven Truth600 categories from RefSeq summaries."""
import argparse, csv, hashlib, json, random
from pathlib import Path

COUNTS = {"b": 351, "a": 99, "f": 50, "p": 50, "vm": 15, "vo": 15, "i": 20}
GROUPS = {
    "accession_aemicros_list.txt": ("b", "a", "f"),
    "accession_aeanimals_list.txt": ("vm", "vo", "i"),
    "accession_aeplants_list.txt": ("p",),
}

def eligible(path):
    records = {}
    with path.open(encoding="utf-8", errors="replace", newline="") as handle:
        for row in csv.reader(handle, delimiter="\t"):
            if row and not row[0].startswith("#") and len(row) >= 20:
                accession, ftp = row[0].strip(), row[19].strip()
                if accession and ftp and ftp.lower() != "na":
                    records[accession] = ftp
    return sorted(records.items())

def write_lines(path, values):
    path.write_text("".join(f"{x}\n" for x in values), encoding="utf-8")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--seed", type=int, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rng, selected = random.Random(args.seed), {}
    audit = {"seed": args.seed, "category_counts": COUNTS, "categories": {}}
    for category, count in COUNTS.items():
        summary = args.summary_dir / f"{category}_assembly_summary.txt"
        candidates = eligible(summary)
        if len(candidates) < count:
            raise SystemExit(f"ERROR: {summary} has {len(candidates)} eligible records; need {count}")
        chosen = sorted(rng.sample(candidates, count))
        selected[category] = chosen
        write_lines(args.output_dir / f"{category}_selected_accessions.txt", (x[0] for x in chosen))
        with (args.output_dir / f"{category}_selected_accession_ftp.tsv").open("w", encoding="utf-8", newline="") as handle:
            writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
            writer.writerow(("accession", "ftp_path")); writer.writerows(chosen)
        audit["categories"][category] = {
            "eligible": len(candidates), "selected": count, "summary": summary.name,
            "summary_sha256": hashlib.sha256(summary.read_bytes()).hexdigest()}
    for filename, categories in GROUPS.items():
        write_lines(args.output_dir / filename,
                    (acc for category in categories for acc, _ in selected[category]))
    (args.output_dir / "selection_manifest.json").write_text(
        json.dumps(audit, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Selected 600 assemblies in seven categories: {args.output_dir}")

if __name__ == "__main__":
    main()
