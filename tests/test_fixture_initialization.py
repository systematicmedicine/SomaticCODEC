"""
--- test_lightweight_test_run_initialization.py

This tests forces the creation of fixtures required for downstream tests.

The purpose of this is to seperate errors that occur in creation of these fixtures, from genuine test cases failing

Author: Cameron Fraser
"""

import pytest

pytestmark = pytest.mark.order(4)

# Ensure fixture runs successfully before any dependent tests
def test_lightweight_test_run_initialization(lightweight_test_run):
    pass