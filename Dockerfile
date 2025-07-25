# ------------------------------------------------------------------------------
# Dockerfile for the codec-opensource pipeline
#
# Description : Builds a Docker image with all dependencies needed to run
#               the Snakemake-based bioinformatics pipeline for variant calling.
# Maintainers : Cameron Fraser, James Phie <info@systematicmedicine.com>
# Base image  : Ubuntu:24.04
# Notes       : fgbio is built from a custom commit for duplex support.
# ------------------------------------------------------------------------------

# Define base image
FROM ubuntu:24.04

# Configure environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:/opt/conda/envs/codec-env/bin:/root/.cargo/bin:$PATH"
SHELL ["/bin/bash", "-c"]

# Install Linux packages
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
    gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Conda packages using Mambaforge
ENV MINIFORGE_VERSION=25.3.0-3
ENV MINIFORGE_URL=https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-Linux-x86_64.sh

RUN wget --quiet ${MINIFORGE_URL} -O miniforge.sh && \
    bash miniforge.sh -b -p /opt/conda && \
    rm miniforge.sh

COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && conda clean -afy

ENV PATH="/opt/conda/envs/codec-env/bin:/opt/conda/bin:/root/.cargo/bin:$PATH"
ENV CONDA_DEFAULT_ENV=codec-env

# Install fgbio feature branch
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99E82A75642AC823" | \
    gpg --dearmor > /usr/share/keyrings/sbt-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/sbt-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" \
    > /etc/apt/sources.list.d/sbt.list && \
    apt-get update && apt-get install -y sbt git default-jdk && \
    git clone https://github.com/fulcrumgenomics/fgbio.git && \
    cd fgbio && \
    git checkout 61db498 && \
    sbt assembly && \
    mkdir -p /opt/fgbio && \
    cp target/scala-2.13/fgbio-*.jar /opt/fgbio/fgbio.jar && \
    echo -e '#!/bin/bash\nexec java ${JAVA_OPTS} -jar /opt/fgbio/fgbio.jar "$@"' > /usr/local/bin/fgbio && \
    chmod +x /usr/local/bin/fgbio && \
    rm -rf ~/.sbt ~/.ivy2 ~/.cache /var/lib/apt/lists/*

# Cleanup
WORKDIR /work
VOLUME ["/work"]

RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env" >> ~/.bashrc
CMD ["bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env && exec bash"]
