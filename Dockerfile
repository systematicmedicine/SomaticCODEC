FROM ubuntu:24.04

# Set working directory (overridden later to /work)
WORKDIR /root

# Avoid interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Set PATH for conda and conda env
ENV PATH="/opt/conda/bin:/opt/conda/envs/codec-env/bin:/root/.cargo/bin:$PATH"

# Use bash as default shell
SHELL ["/bin/bash", "-c"]

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget curl git nano python3-pip \
    ca-certificates bzip2 liblzma-dev zlib1g-dev libbz2-dev \
    build-essential \
 && pip install --break-system-packages awscli \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_24.1.2-0-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    /opt/conda/bin/conda init bash

# Create and populate conda environment
RUN /opt/conda/bin/conda create -y -n codec-env python=3.9 && \
    /opt/conda/bin/conda run -n codec-env conda install -y -c conda-forge -c bioconda \
        bwa-mem2 \
        tmux \
        samtools \
        fgbio \
        picard \
        pandas \
        seaborn \
        pysam \
        numpy \
        matplotlib \
        scipy \
        biopython \
        cyvcf2 \
        click \
        quicksect \
        snakemake \
        seqkit \
        bedtools \
        fastqc \
        cutadapt \
        fastp \
        umi_tools \
        graphviz \
        python-graphviz \
        perl && \
    /opt/conda/bin/conda clean -afy

# Auto-activate codec-env when bash starts
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env" >> ~/.bashrc

# Declare volume and set default working directory
VOLUME ["/work"]
WORKDIR /work

# Default command: activate env and launch bash
CMD ["bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env && exec bash"]