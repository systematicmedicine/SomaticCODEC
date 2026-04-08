"""
--- test_docker.py ---

Checks if the test suite is being run using an up-to-date docker image

Authors:
    - Cameron Fraser
"""

# Import libraries
import os
import hashlib
import pytest
from pathlib import Path
import re
import yaml

# Pytest marks
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(1)
]


# Define hard coded parameters
from tests.conftest import PROJECT_ROOT
IMAGE_INFO_SHA_FILE = "/image-info/dockerfile.sha256"
IMAGE_INFO_ENVIRONMENT_SHA = "/image-info/environment.sha256"
LOCAL_DOCKERFILE = PROJECT_ROOT / "Dockerfile"
LOCAL_ENVIRONMENT = PROJECT_ROOT / "dependencies.yml"

# Returns true if running inside docker container
def is_inside_docker() -> bool:
    # Detect cgroup v1 and v2 hints
    try:
        with open("/proc/1/cgroup", "rt") as f:
            content = f.read()
        if "docker" in content or "containerd" in content:
            return True
    except FileNotFoundError:
        pass

    # Fallback: check for /.dockerenv file
    if os.path.exists("/.dockerenv"):
        return True

    return False


# Returns sha256sum for a file 
def sha256sum(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

# Checks that tests are being run within a Docker container
def test_running_inside_docker():
    assert is_inside_docker(), "Test must be run inside a Docker container."

# Checks that Dockerfile sha256 sum matches
def test_dockerfile_sha256_matches():
    if not LOCAL_DOCKERFILE.exists():
        pytest.fail("Local Dockerfile not found in PROJECT_ROOT.")

    try:
        with open(IMAGE_INFO_SHA_FILE, "rt") as f:
            image_sha = f.read().strip()
    except FileNotFoundError:
        pytest.fail(f"File not found in container: {IMAGE_INFO_SHA_FILE}")

    local_sha = sha256sum(LOCAL_DOCKERFILE)

    assert image_sha == local_sha, (
        f"Dockerfile SHA mismatch:\n"
        f"  Local: {local_sha}\n"
        f"  Image: {image_sha}"
    )

# Checks that dependencies.yml sha256sum matchs
def test_environment_sha256_matches():
    if not LOCAL_ENVIRONMENT.exists():
        pytest.fail("Local dependencies.yml not found in PROJECT_ROOT.")

    try:
        with open(IMAGE_INFO_ENVIRONMENT_SHA, "rt") as f:
            image_sha = f.read().strip()
    except FileNotFoundError:
        pytest.fail(f"File not found in container: {IMAGE_INFO_ENVIRONMENT_SHA}")

    local_sha = sha256sum(LOCAL_ENVIRONMENT)

    assert image_sha == local_sha, (
        f"dependencies.yml SHA mismatch:\n"
        f"  Local: {local_sha}\n"
        f"  Image: {image_sha}"
    )

# Checks that all dependencies have an explicit version specified
def test_environment_pins_versions():
    if not LOCAL_ENVIRONMENT.exists():
        pytest.fail("Local dependencies.yml not found.")

    with open(LOCAL_ENVIRONMENT, "r") as f:
        env = yaml.safe_load(f)

    conda_packages = env.get("dependencies", [])
    pip_packages = []

    # Extract pip sublist if present
    for dep in conda_packages:
        if isinstance(dep, dict) and "pip" in dep:
            pip_packages = dep["pip"]

    # Helper: check version format
    def is_version_pinned(pkg_str, conda=True):
        if conda:
            return re.match(r"^[a-zA-Z0-9_.+-]+(=|==)[0-9]", pkg_str) is not None
        else:
            return re.match(r"^[a-zA-Z0-9_.+-]+==[0-9]", pkg_str) is not None

    # Check conda dependencies
    unpinned_conda = [
        pkg for pkg in conda_packages
        if isinstance(pkg, str) and not is_version_pinned(pkg, conda=True)
    ]

    # Check pip dependencies
    unpinned_pip = [
        pkg for pkg in pip_packages
        if not is_version_pinned(pkg, conda=False)
    ]

    assert not unpinned_conda and not unpinned_pip, (
        "Unpinned dependencies found:\n" +
        (f"Conda: {unpinned_conda}\n" if unpinned_conda else "") +
        (f"Pip: {unpinned_pip}\n" if unpinned_pip else "")
    )