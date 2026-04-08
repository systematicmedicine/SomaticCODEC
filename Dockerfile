# ==============================================================================
# Dockerfile for the codec-opensource pipeline
#
# Description       : Builds a Docker image with all dependencies needed to run the codec-opensource pipeline.
# Maintainer        : Cameron Fraser <info@systematicmedicine.com>
# Base image        : Ubuntu 24.04
# Package sources   : All software installed via APT or Conda (see dependencies.yml)
# ==============================================================================

# ------------------------------------------------------------------------------
# BASE CONFIGURATION
# ------------------------------------------------------------------------------

FROM ubuntu:24.04

# Set non-interactive mode for APT
ENV DEBIAN_FRONTEND=noninteractive

# Extend default PATH to include conda and other tools
ENV PATH="/opt/conda/bin:/opt/conda/envs/codec-env/bin:/root/.cargo/bin:$PATH"
SHELL ["/bin/bash", "-c"]

# ------------------------------------------------------------------------------
# INSTALL SYSTEM PACKAGES
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    nano \
    unzip \
    wget \
    default-jdk \
    openjdk-11-jre \
    python3-pip \
    r-base \
    bzip2 \
    ca-certificates \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    gnupg \
    vim && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Install CONDA PACKAGES FROM DEPENDENCIES.YML
# ------------------------------------------------------------------------------
ENV MINIFORGE_VERSION=25.3.0-3
ENV MINIFORGE_URL=https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-Linux-x86_64.sh

RUN wget --quiet ${MINIFORGE_URL} -O miniforge.sh && \
    bash miniforge.sh -b -p /opt/conda && \
    rm miniforge.sh

# Install conda environment from dependencies.yml
COPY dependencies.yml /tmp/dependencies.yml
RUN conda env create -f /tmp/dependencies.yml && conda clean -afy

# Re-assert environment variables after conda setup
ENV PATH="/opt/conda/envs/codec-env/bin:/opt/conda/bin:/root/.cargo/bin:$PATH"
ENV CONDA_DEFAULT_ENV=codec-env

# ------------------------------------------------------------------------------
# CAPTURE IMAGE BUILD METADATA (PROVENANCE)
# ------------------------------------------------------------------------------
COPY Dockerfile /tmp/Dockerfile
COPY dependencies.yml /tmp/dependencies.yml
RUN mkdir -p /image-info && \
    cp /tmp/Dockerfile /image-info/Dockerfile && \
    cp /tmp/dependencies.yml /image-info/dependencies.yml && \
    sha256sum /image-info/Dockerfile | awk '{print $1}' > /image-info/dockerfile.sha256 && \
    sha256sum /image-info/dependencies.yml | awk '{print $1}' > /image-info/environment.sha256

# ------------------------------------------------------------------------------
# FINAL SETUP
# ------------------------------------------------------------------------------

# Final cleanup
RUN rm -rf ~/.sbt ~/.ivy2 ~/.cache /var/lib/apt/lists/* /tmp/Dockerfile

# Set working directory and mount point
WORKDIR /work
VOLUME ["/work"]

# Allow Git access to pipeline directory
ENV GIT_CONFIG_GLOBAL=/etc/gitconfig
RUN git config --system --add safe.directory /work/codec-opensource

# Automatically activate conda environment on login
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env" >> ~/.bashrc
CMD ["bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env && exec bash"]
