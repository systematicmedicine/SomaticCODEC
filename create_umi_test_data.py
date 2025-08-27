import gzip

def add_test_umi(in_file, out_file):
    with gzip.open(in_file, "rt") as fin, gzip.open(out_file, "wt") as fout:
        while True:
            header = fin.readline()
            if not header:
                break
            seq = fin.readline()
            plus = fin.readline()
            qual = fin.readline()

            parts = header.strip().split()
            if len(parts) < 2:
                fout.write(header + seq + plus + qual)
                continue

            idx_info = parts[1]  # e.g. "1:N:0:TTACCGAC+CGTATTCG"
            
            # split the last part at '+'
            idx_parts = idx_info.split(":")
            last_part = idx_parts[-1]
            if "+" in last_part:
                i7, i5 = last_part.split("+")
            else:
                i7, i5 = last_part, "NNNNNNNN"

            # insert 12 A's as UMI after i7
            umi = "A" * 12
            idx_parts[-1] = f"{i7}{umi}+{i5}"

            # rewrite header
            parts[1] = ":".join(idx_parts)
            fout.write(" ".join(parts) + "\n" + seq + plus + qual)

# Example usage
add_test_umi("tests/data/lightweight_test_run/S005_Chr21_10000reads_r1.fastq.gz",
             "tests/data/lightweight_test_run/S005_Chr21_10000reads_r1_umi.fastq.gz")

add_test_umi("tests/data/lightweight_test_run/S005_Chr21_10000reads_r2.fastq.gz",
             "tests/data/lightweight_test_run/S005_Chr21_10000reads_r2_umi.fastq.gz")
