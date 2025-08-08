"""
--- test_docker.py ---

Checks if the test suite is being run using an up-to-date docker image

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import os
import hashlib
import pytest
from pathlib import Path

# Pytest marks
# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(1)
]


# Define hard coded parameters
PROJECT_ROOT = Path(__file__).resolve().parent.parent
IMAGE_INFO_SHA_FILE = "/image-info/dockerfile.sha256"
IMAGE_INFO_ENVIRONMENT_SHA = "/image-info/environment.sha256"
LOCAL_DOCKERFILE = PROJECT_ROOT / "Dockerfile"
LOCAL_ENVIRONMENT = PROJECT_ROOT / "environment.yml"

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

# Checks that environment.yml sha256sum matchs
def test_environment_sha256_matches():
    if not LOCAL_ENVIRONMENT.exists():
        pytest.fail("Local environment.yml not found in PROJECT_ROOT.")

    try:
        with open(IMAGE_INFO_ENVIRONMENT_SHA, "rt") as f:
            image_sha = f.read().strip()
    except FileNotFoundError:
        pytest.fail(f"File not found in container: {IMAGE_INFO_ENVIRONMENT_SHA}")

    local_sha = sha256sum(LOCAL_ENVIRONMENT)

    assert image_sha == local_sha, (
        f"environment.yml SHA mismatch:\n"
        f"  Local: {local_sha}\n"
        f"  Image: {image_sha}"
    )
