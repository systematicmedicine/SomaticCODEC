"""
--- test_lightweight_test_run_initialization.py ---

This tests forces the creation of fixtures required for downstream tests.

The purpose of this is to decouple fixture creation from the running of dependent tests

Author: Cameron Fraser
"""

import pytest

pytestmark = pytest.mark.order(9)

# Ensure fixture runs successfully before any dependent tests
def test_lightweight_test_run_initialization(lightweight_test_run):
    pass