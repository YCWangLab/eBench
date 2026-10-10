#!/usr/bin/env python3

import argparse
from contextlib import contextmanager
import os
import subprocess
import sys


def get_sq_name(line):
    fields = line.rstrip("\n").split("\t")
    for field in fields:
        if field.startswith("SN:"):
            return field[3:]
    return None


def keep_alignment(fields, max_len):
    if len(fields) < 11:
        return False
    rname = fields[2]
    seq = fields[9]
    if rname == "*":
        return False
    if seq == "*":
        return False
    if max_len > 0 and len(seq) >= max_len:
        return False
    return True


def is_sam_text(path):
    """Return True for SAM text and False for BAM/CRAM input."""
    with open(path, "rb") as fh:
        prefix = fh.read(4)
    return prefix.startswith(b"@")


@contextmanager
def alignment_stream(path, header=False):
    """Yield a text stream from SAM, BAM, or CRAM and verify samtools exit status."""
    if is_sam_text(path):
        fh = open(path, "r", errors="replace")
        try:
            yield fh
        finally:
            fh.close()
        return

    command = ["samtools", "view"]
    if header:
        command.append("-H")
    command.append(path)
    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        text=True,
        errors="replace",
    )
    if proc.stdout is None:
        raise RuntimeError(f"Could not read alignment input: {path}")
    try:
        yield proc.stdout
    finally:
        proc.stdout.close()
        return_code = proc.wait()
        if return_code != 0:
            raise RuntimeError(
                f"samtools view failed for {path} with exit code {return_code}"
            )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Merge Bowtie2 SAM/BAM/CRAM shards into one query-name sorted binary BAM "
            "with a compact @SQ header, without writing a giant intermediate SAM body."
        )
    )
    parser.add_argument("--output", required=True)
    parser.add_argument("--tmpdir", required=True)
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument(
        "--max-len",
        type=int,
        default=200,
        help="Keep reads with SEQ length < max_len. Use 0 to disable length filtering."
    )
    parser.add_argument("inputs", nargs="+")
    args = parser.parse_args()

    os.makedirs(args.tmpdir, exist_ok=True)
    outdir = os.path.dirname(args.output)
    if outdir:
        os.makedirs(outdir, exist_ok=True)

    header_file = os.path.join(args.tmpdir, "compact.header.sam")

    used_refs = set()
    total_alignments = 0
    kept_alignments = 0
    skipped_unmapped = 0
    skipped_seq_star = 0
    skipped_length = 0

    print("[merge_compact] PASS1: scanning SAM alignment bodies", file=sys.stderr)
    if args.max_len == 0:
        print("[merge_compact] length filter: DISABLED", file=sys.stderr)
    else:
        print(f"[merge_compact] length filter: SEQ length < {args.max_len}", file=sys.stderr)

    for path in args.inputs:
        print(f"[merge_compact] scan body: {path}", file=sys.stderr)
        with alignment_stream(path) as fh:
            for line in fh:
                if not line or line.startswith("@"):
                    continue

                fields = line.rstrip("\n").split("\t")
                if len(fields) < 11:
                    continue

                total_alignments += 1
                rname = fields[2]
                seq = fields[9]

                if rname == "*":
                    skipped_unmapped += 1
                    continue
                if seq == "*":
                    skipped_seq_star += 1
                    continue
                if args.max_len > 0 and len(seq) >= args.max_len:
                    skipped_length += 1
                    continue

                used_refs.add(rname)
                kept_alignments += 1

    print(f"[merge_compact] total alignments: {total_alignments}", file=sys.stderr)
    print(f"[merge_compact] kept alignments: {kept_alignments}", file=sys.stderr)
    print(f"[merge_compact] skipped unmapped: {skipped_unmapped}", file=sys.stderr)
    print(f"[merge_compact] skipped SEQ='*': {skipped_seq_star}", file=sys.stderr)
    print(f"[merge_compact] skipped by length: {skipped_length}", file=sys.stderr)
    print(f"[merge_compact] used references: {len(used_refs)}", file=sys.stderr)

    if kept_alignments == 0:
        if args.max_len > 0:
            raise SystemExit(
                "ERROR: zero alignments remain after length filtering. "
                f"Requested SEQ length < {args.max_len}."
            )
        raise SystemExit("ERROR: zero mapped alignments remain.")

    print("[merge_compact] PASS2: building compact header", file=sys.stderr)

    seen_refs = set()
    with open(header_file, "w") as out:
        out.write("@HD\tVN:1.6\tSO:queryname\tGO:query\n")

        for path in args.inputs:
            print(f"[merge_compact] scan header: {path}", file=sys.stderr)
            with alignment_stream(path, header=True) as fh:
                for line in fh:
                    if not line.startswith("@"):
                        break
                    if not line.startswith("@SQ\t"):
                        continue

                    ref = get_sq_name(line)
                    if ref is None or ref not in used_refs or ref in seen_refs:
                        continue

                    out.write(line)
                    seen_refs.add(ref)

    missing = used_refs - seen_refs
    if missing:
        missing_file = os.path.join(args.tmpdir, "missing_reference_headers.txt")
        with open(missing_file, "w") as out:
            for ref in sorted(missing):
                out.write(ref + "\n")
        raise SystemExit(
            f"ERROR: {len(missing)} used RNAMEs have no matching @SQ line. "
            f"See: {missing_file}"
        )

    header_size = os.path.getsize(header_file)
    print(f"[merge_compact] compact header references: {len(seen_refs)}", file=sys.stderr)
    print(f"[merge_compact] compact header bytes: {header_size}", file=sys.stderr)

    if header_size >= 2_000_000_000:
        raise SystemExit("ERROR: compact header is near or above the BAM header limit.")

    print(
        "[merge_compact] PASS3: streaming retained alignments to samtools sort",
        file=sys.stderr
    )

    sort_prefix = os.path.join(args.tmpdir, "samtools_sort")
    sort_cmd = [
        "samtools", "sort", "-n",
        "-@", str(args.threads),
        "-m", "2G",
        "-T", sort_prefix,
        "-O", "BAM",
        "-o", args.output,
        "-"
    ]

    sort_proc = subprocess.Popen(sort_cmd, stdin=subprocess.PIPE)
    if sort_proc.stdin is None:
        raise RuntimeError("Could not open stdin pipe to samtools sort.")

    try:
        with open(header_file, "rb") as header_in:
            while True:
                chunk = header_in.read(1024 * 1024)
                if not chunk:
                    break
                sort_proc.stdin.write(chunk)

        streamed = 0
        for path in args.inputs:
            print(f"[merge_compact] stream body: {path}", file=sys.stderr)
            with alignment_stream(path) as fh:
                for line in fh:
                    if not line or line.startswith("@"):
                        continue
                    fields = line.rstrip("\n").split("\t")
                    if not keep_alignment(fields, args.max_len):
                        continue
                    sort_proc.stdin.write(line.encode("utf-8"))
                    streamed += 1

        print(f"[merge_compact] streamed alignments: {streamed}", file=sys.stderr)

    except BrokenPipeError:
        try:
            sort_proc.stdin.close()
        except Exception:
            pass
        rc = sort_proc.wait()
        raise SystemExit(
            "ERROR: samtools sort closed the pipe early. "
            f"Exit code: {rc}"
        )

    finally:
        try:
            if sort_proc.stdin and not sort_proc.stdin.closed:
                sort_proc.stdin.close()
        except Exception:
            pass

    sort_rc = sort_proc.wait()
    if sort_rc != 0:
        raise SystemExit(f"ERROR: samtools sort failed with exit code {sort_rc}")

    print("[merge_compact] PASS4: samtools quickcheck", file=sys.stderr)
    qc = subprocess.run(["samtools", "quickcheck", "-v", args.output])
    if qc.returncode != 0:
        raise SystemExit("ERROR: samtools quickcheck failed")

    print("[merge_compact] SUCCESS", file=sys.stderr)
    print(f"[merge_compact] output: {args.output}", file=sys.stderr)
    print(f"[merge_compact] output size: {os.path.getsize(args.output)} bytes", file=sys.stderr)


if __name__ == "__main__":
    main()
