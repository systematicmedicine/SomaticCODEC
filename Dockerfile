FROM ubuntu:24.04

# Set working directory (overridden later to /work)
WORKDIR /root

# Avoid interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Set PATH for conda and conda env
ENV PATH="/opt/conda/bin:/opt/conda/envs/codec-env/bin:/root/.cargo/bin:$PATH"

# Use bash as default shell
SHELL ["/bin/bash", "-c"]

# Install system dependencies (including Java runtime for fgbio)
RUN apt-get update && apt-get install -y \
    wget curl git nano python3-pip unzip default-jdk \
    ca-certificates bzip2 liblzma-dev zlib1g-dev libbz2-dev \
    build-essential openjdk-11-jre r-base \
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
        #fgbio \ This will be added in place of feature branch build once CallCodecConsensusReads is added to fgbio
        picard \
        gatk4 \
        bcftools \
        bedops \
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
        varscan \
        pytest \
        perl && \
    /opt/conda/bin/conda clean -afy

# Make varscan available as a direct command
RUN VARSCAN_JAR=$(find /opt/conda/envs/codec-env -name 'VarScan.jar') && \
    echo -e '#!/bin/bash\nexec java -jar '"$VARSCAN_JAR"' "$@"' > /opt/conda/envs/codec-env/bin/varscan && \
    chmod +x /opt/conda/envs/codec-env/bin/varscan

# Install required R packages
RUN Rscript -e 'install.packages(c("dplyr", "jsonlite"), repos="https://mirror.aarnet.edu.au/pub/CRAN/")' \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install feature branch of fgbio (replace with conda install when CallCodecConsensusReads is added to main branch)
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99E82A75642AC823" | \
    gpg --dearmor > /usr/share/keyrings/sbt-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/sbt-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" \
    > /etc/apt/sources.list.d/sbt.list && \
    apt-get update && apt-get install -y sbt git default-jdk && \
    git clone --single-branch --branch feature/codec https://github.com/fulcrumgenomics/fgbio.git && \
    cd fgbio && sbt assembly && \
    mkdir -p /opt/fgbio && \
    cp target/scala-2.13/fgbio-*.jar /opt/fgbio/fgbio.jar && \
    echo -e '#!/bin/bash\nexec java ${JAVA_OPTS} -jar /opt/fgbio/fgbio.jar "$@"' > /usr/local/bin/fgbio && \
    chmod +x /usr/local/bin/fgbio && \
    rm -rf ~/.sbt ~/.ivy2 ~/.cache /var/lib/apt/lists/*

# Optional: set workdir and default entrypoint
WORKDIR /work

# Auto-activate codec-env when bash starts
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env" >> ~/.bashrc

# Declare volume and set default working directory
VOLUME ["/work"]
WORKDIR /work

# Default command: activate env and launch bash
CMD ["bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate codec-env && exec bash"]