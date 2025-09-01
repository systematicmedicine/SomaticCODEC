"""
--- test_check_variant_calling_chroms_present.py ---

Test that the script check_variant_calling_chroms_present.py can detect missing chromosomes in FAI and BED files

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

from pathlib import Path
import sys
import pytest
from types import SimpleNamespace

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.check_variant_calling_chroms_present import main

@pytest.mark.parametrize(
    "fai_path, bed_path, chroms, expect_exit, expect_done, expect_error_chrom",
    [
        # All chroms present
        (
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.fna.fai",
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.bed",
            ["chr1", "chr2"],
            None,    # no exit
            True,    # done file created
            None     # no missing chrom
        ),
        # Missing chrom in FAI
        (
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.fna.fai",
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.bed",
            ["chr1", "chr3"],
            1,       # exit code
            False,   # done file not created
            "chr3"   # should be mentioned in log
        ),
        # Missing chrom in BED
        (
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.fna.fai",
            "tests/data/test_check_variant_calling_chroms_present/chr1and2.bed",
            ["chr1", "chr4"],
            1,       # exit code
            False,   # done file not created
            "chr4"   # should be mentioned in log
        )
    ]
)
def test_check_variant_calling_chroms_present(tmp_path, fai_path, bed_path, chroms, expect_exit, expect_done, expect_error_chrom):
    fai_file = Path(fai_path)
    bed_file = Path(bed_path)

    done_file = tmp_path / "check.done"
    log_file = tmp_path / "log.log"

    # Mock Snakemake object
    class FakeSnakemake:
        input = SimpleNamespace(
            fai=str(fai_file),
            precomputed_masks=[str(bed_file)]
        )
        output = [str(done_file)]
        params = SimpleNamespace(
            variant_calling_chroms=chroms
        )
        log = [str(log_file)]

    # Run script
    if expect_exit is not None:
        with pytest.raises(SystemExit) as e:
            main(FakeSnakemake())
        assert e.value.code == expect_exit
    else:
        main(FakeSnakemake())

    # Check for done file
    assert done_file.exists() == expect_done

    # --- Read done file ---
    log_text = log_file.read_text()
    if expect_error_chrom:
        assert expect_error_chrom in log_text
        assert "Missing variant calling chromosomes" in log_text
    else:
        assert "All variant calling chromosomes are present" in log_text

