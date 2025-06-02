FROM ubuntu:24.04.1
WORKDIR /work

# Avoid prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:/opt/conda/envs/codec-env/bin:/root/.cargo/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget curl git nano awscli \
    ca-certificates bzip2 liblzma-dev zlib1g-dev libbz2-dev \
    build-essential \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda --no-default-packages && \
    rm miniconda.sh

# Create and populate conda environment
RUN conda create -y -n codec-env python=3.9 && \
    /opt/conda/envs/codec-env/bin/conda install -y -c conda-forge -c bioconda \
        bwa \
        bwa-mem2 \
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
        perl \
 && conda clean -afy