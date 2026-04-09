"""
--- test_lightweight_test_run_initialization.py

This tests forces the creation of fixtures required for downstream tests.

The purpose of this is to decouple fixture creation from the running of dependent tests

Author: Cameron Fraser
"""

import pytest

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(8)
]

# Ensure fixture runs successfully before any dependent tests
def test_dryrun_initialization(dryrun_fixture):
    pass