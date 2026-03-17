"""
--- test_check_included_chromosomes_present.py ---

Test that the script check_included_chromosomes_present.py can detect missing chromosomes in FAI and BED files

Authors:
    - Joshua Johnstone
"""

from pathlib import Path
import pytest
import types
from rule_scripts.shared.setup.check_included_chromosomes_present import main

@pytest.mark.parametrize(
    "fai_path, bed_path, chroms, expect_exit, expect_done, expect_error_chrom",
    [
        # All chroms present
        (
            "tests/data/test_check_included_chromosomes_present/chr1and2.fna.fai",
            ["tests/data/test_check_included_chromosomes_present/chr1and2.bed"],
            ["chr1", "chr2"],
            None,    # no exit
            True,    # done file created
            None     # no missing chrom
        ),
        # Missing chrom in FAI
        (
            "tests/data/test_check_included_chromosomes_present/chr1and2.fna.fai",
            ["tests/data/test_check_included_chromosomes_present/chr1and2.bed"],
            ["chr1", "chr3"],
            1,       # exit code
            False,   # done file not created
            "chr3"   # should be mentioned in log
        ),
        # Missing chrom in BED
        (
            "tests/data/test_check_included_chromosomes_present/chr1and2.fna.fai",
            ["tests/data/test_check_included_chromosomes_present/chr1and2.bed"],
            ["chr1", "chr4"],
            1,       # exit code
            False,   # done file not created
            "chr4"   # should be mentioned in log
        )
    ]
)
def test_check_included_chromosomes_present(tmp_path, fai_path, bed_path, chroms, expect_exit, expect_done, expect_error_chrom):

    done_file = tmp_path / "check.done"
    log_file = tmp_path / "log.log"

    # Define test arguments
    args = types.SimpleNamespace(
        fai=fai_path,
        precomputed_masks=bed_path,
        included_chromosomes=chroms,
        done_file=done_file,
        log=log_file
    )

    # Run script
    if expect_exit is not None:
        with pytest.raises(SystemExit) as e:
            main(args=args)
        assert e.value.code == expect_exit
    else:
        main(args=args)

    # Check for done file
    assert done_file.exists() == expect_done

    # --- Read done file ---
    log_text = log_file.read_text()
    if expect_error_chrom:
        assert expect_error_chrom in log_text
        assert " Missing chromosomes included for variant calling" in log_text
    else:
        assert "All chromosomes included for variant calling are present" in log_text

