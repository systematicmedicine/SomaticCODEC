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


## Folder structure
```
.
├── config
│
├── data
│   ├── combined_bed        # All regions to mask
│   ├── ex_cand_vcf         # Candidate somatic mutations for experimental samples
│   ├── ex_demux_fq         # Demultiplexed FASTQ files for experimental samples
│   ├── ex_dsc_bam          # Double stranded consensus for experimental samples
│   ├── ex_filt_vcf         # Filtered somatic mutations for experimental samples
│   ├── ex_proc_fq          # Trimmed and quality filtered FASTQ files for experimental samples
│   ├── ex_raw_bam          # Raw alignments for experimental samples
│   ├── ex_raw_fq           # Raw FASTQ files for experimental samples
│   ├── ex_ssc_bam          # Single stranded consensus for experimental samples
│   ├── ms_cand_vcf         # Candidate germline mutatations for matched samples
│   ├── ms_demux_fq         # Demultiplexed FASTQ files for matched samples
│   ├── ms_filt_vcf         # Filtered germline mutations for matched samples
│   ├── ms_hetero_bed       # All heterozygous regions masked
│   ├── ms_lowdepth_bed     # All low depth regions masked
│   ├── ms_proc_fq          # Trimmed and quality filtered FASTQ files for matched samples
│   ├── ms_raw_bam          # Raw alignments for matched samples
│   ├── personal_ref_fa     # Personalised refernces created for each sample
│   └── pon_vcf             # Pannel of normals
│
├── rules
│               
├── scripts
│
├── README.md
├── Snakefile

```