"""
--- fasta_helpers.py ---

Functions for obtaining data from FASTA files.

Authors: 
    - Joshua Johnstone
"""
from pathlib import Path
import gzip

# Counts the number of sequences in a FASTA file
def count_fasta_data_points(path):
    path = Path(path)
    open_func = open
    if str(path).endswith(".gz"):
        open_func = gzip.open
    count = 0
    with open_func(path, 'rt') as file:
        for line in file:
            if line.startswith('>'):
                count += 1
    return count

# Checks that the file has correct FASTA structure
def check_fasta_structure(path):
    path = Path(path)
    open_func = open
    if str(path).endswith(".gz"):
        open_func = gzip.open

    with open_func(path, 'rt') as file:
        lines = [line.rstrip('\n') for line in file if line.strip()]

    assert len(lines) % 2 == 0, f"FASTA file {path} does not have alternating header/sequence lines (lines: {len(lines)})."

    for line in range(0, len(lines), 2):
        header = lines[line]
        sequence = lines[line + 1]

        assert header.startswith(">"), f"Line {line+1} does not start with '>': {header}"
        assert len(header) > 1, f"Header on line {line+1} is empty."

        valid_bases = set("ACGTNacgtn")
        invalid_chars = set(sequence) - valid_bases
        assert not invalid_chars, f"Invalid characters {invalid_chars} in sequence on line {line+2}: {sequence}"
        assert len(sequence) > 0, f"Empty sequence on line {line+2}."

# Returns the first n lines of a FASTA file
def print_fasta_first_n_lines(path, n_lines):
    opener = gzip.open if str(path).endswith(".gz") else open
    lines = []
    with opener(path, "rt") as f:
        for i, line in enumerate(f):
            if i >= n_lines:
                break
            lines.append(line.rstrip())
    return "\n".join(lines)