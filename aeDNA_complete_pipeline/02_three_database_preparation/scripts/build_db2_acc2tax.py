#!/usr/bin/env python3
import argparse
from pathlib import Path


def parse_record(line):
    s = line.rstrip("\n")
    if not s or s.startswith("#"):
        return None
    cols = s.split("\t")
    if len(cols) == 1:
        cols = s.split()
    low = [x.lower() for x in cols]
    if any(x in {"taxid", "tax_id"} for x in low):
        return None
    # NCBI accession2taxid: accession, accession.version, taxid, gi
    if len(cols) >= 3 and cols[2].isdigit():
        return {"keys": {cols[0], cols[1]}, "taxid": cols[2], "line": s}
    # Compact form: accession(.version), taxid
    if len(cols) >= 2 and cols[1].isdigit():
        return {"keys": {cols[0]}, "taxid": cols[1], "line": s}
    return None


def load_valid_taxids(nodes_path):
    valid = set()
    with open(nodes_path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            # nodes.dmp: tax_id | parent_tax_id | rank | ...
            first = line.split("|", 1)[0].strip()
            if first.isdigit():
                valid.add(first)
    return valid


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--standard", required=True)
    ap.add_argument("--truth", required=True)
    ap.add_argument("--nodes", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--conflicts", required=True)
    ap.add_argument("--summary", required=True)
    ap.add_argument("--invalid-truth-taxids", required=True)
    args = ap.parse_args()

    truth_records = []
    key_to_indices = {}
    with open(args.truth, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            rec = parse_record(line)
            if rec is None:
                continue
            idx = len(truth_records)
            truth_records.append(rec)
            for k in rec["keys"]:
                key_to_indices.setdefault(k, []).append(idx)

    seen = set()
    conflicts = []
    standard_records = 0
    overlap_records = 0

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as out, open(
        args.standard, "r", encoding="utf-8", errors="replace"
    ) as std:
        # Keep the standard accession2taxid exactly as the authoritative base.
        for line in std:
            out.write(line)
            rec = parse_record(line)
            if rec is None:
                continue
            standard_records += 1
            matched = set()
            for k in rec["keys"]:
                matched.update(key_to_indices.get(k, []))
            if matched:
                overlap_records += 1
                for idx in matched:
                    seen.add(idx)
                    tr = truth_records[idx]
                    if tr["taxid"] != rec["taxid"]:
                        # Standard wins for overlapping accessions because nodes/names
                        # and the large reference database come from the same taxonomy snapshot.
                        conflicts.append((sorted(rec["keys"])[0], rec["taxid"], tr["taxid"]))

        # Append only truth entries whose accession is absent from the standard table.
        appended_records = []
        for idx, rec in enumerate(truth_records):
            if idx not in seen:
                out.write(rec["line"] + "\n")
                appended_records.append(rec)

    # Validate only newly appended truth taxids against the standard nodes.dmp.
    valid_taxids = load_valid_taxids(args.nodes)
    invalid = []
    for rec in appended_records:
        if rec["taxid"] not in valid_taxids:
            invalid.append((sorted(rec["keys"])[0], rec["taxid"]))

    with open(args.conflicts, "w", encoding="utf-8") as cf:
        cf.write("accession\tstandard_taxid_used\ttruth_taxid_ignored\tresolution\n")
        for a, s, t in conflicts:
            cf.write(f"{a}\t{s}\t{t}\tSTANDARD_WINS\n")

    with open(args.invalid_truth_taxids, "w", encoding="utf-8") as fh:
        fh.write("accession\ttruth_taxid_not_in_nodes\n")
        for a, t in invalid:
            fh.write(f"{a}\t{t}\n")

    with open(args.summary, "w", encoding="utf-8") as sf:
        sf.write(f"standard_records\t{standard_records}\n")
        sf.write(f"truth_records\t{len(truth_records)}\n")
        sf.write(f"truth_records_already_in_standard\t{len(seen)}\n")
        sf.write(f"truth_records_appended\t{len(appended_records)}\n")
        sf.write(f"standard_records_overlapping_truth\t{overlap_records}\n")
        sf.write(f"taxid_conflicts_resolved_standard_wins\t{len(conflicts)}\n")
        sf.write(f"appended_truth_taxids_missing_from_nodes\t{len(invalid)}\n")

    if invalid:
        raise SystemExit(
            f"ERROR: {len(invalid)} truth-only taxids are absent from nodes.dmp. "
            f"Inspect {args.invalid_truth_taxids}. DB2 acc2tax should not be used until these are remapped."
        )

    print(
        f"OK: DB2 acc2tax built. {len(conflicts)} overlapping accession/taxid conflicts "
        f"were resolved with STANDARD_WINS; {len(appended_records)} truth-only records appended."
    )


if __name__ == "__main__":
    main()
