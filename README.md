# codec-opensource
An bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

- Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
- Tailored for detecting somatic mutations in normal tissue
- Incorporates independent samples to build personalized reference genomes
- Additional QC metrics (e.g. `fastqc`)
- Additional pipeline testing

## Installation

## Docker desktop setup (skip for EC2 instances)
* Download docker desktop from https://www.docker.com/products/docker-desktop
* During installation:
  * Enable WSL2 backend
  * Integrate with your Ubuntu distro
* Once installed, restart your computer
* Open Docker Desktop
* Go to settings -> resources -> WSL Integration
* Turn on integratino for your Ubuntu instance 
* Test:
  * docker version
  * docker run hello-world
* Add Docker CLI to WSL PATH:

  ```bash
echo 'export PATH="$PATH:/mnt/c/Program Files/Docker/Docker/resources/bin"' >> ~/.bashrc
source ~/.bashrc
  ```

## Activate docker
* In the repository directory:

  ```bash
docker build -t codec .
  ```

  ```bash
docker run -it --rm \
  -v ~/<folder>/<repo_name>:/work \
  codec
  ```

## Usage

Hello, this is Josh learning GitHub.