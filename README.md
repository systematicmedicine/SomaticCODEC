# codec-opensource
An bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

- Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
- Tailored for detecting somatic mutations in normal tissue
- Incorporates independent samples to build personalized reference genomes
- Additional QC metrics (e.g. `fastqc`)
- Additional pipeline testing

## Intended use
* Quanityifying SNVs in genomic DNA
  * Future updates may include small indels 
* Libraries prepared as per <I>SOP0017 CODECseq library preparation</I>
* Libraries sequenced as per <I>SOP0017 CODECseq library preparation</I>

## Installation and setup

### Local setup (skip for EC2 instances)

#### Docker desktop setup (skip for EC2 instances)
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
* Note: Docker desktop may require up to 32GB ram to run human whole genome alignment steps locally. 

#### Collect reference files
* Download the following files from S3 (sysmed-ref-s3) to codec-opensource/tmp/reference
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.dict
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.pac
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.sa
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.amb
  * GRCh38_notinalldifficultregions.bed
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.ann
  * GRCh38_notinalldifficultregions.interval_list
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwa_index.tar.gz
  * common_all_20180418_with_chr.vcf.gz
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwt
  * common_all_20180418_with_chr.vcf.gz.tbi
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai
  * common_all_20180418_with_chr.vcf.gz
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.0123
  * GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwt.2bit.64

* Download any raw fastq files (most likely smaller test files if running locally)

### EC2 setup (skip for local use)

#### Launch new EC2 instance
* Name instance according to project and user
* Select Deep Learning base OSS Nvidia Driver GPU AMI (Ubuntu 24.04)
* Select instance type (recommended m6i.24xlarge if running large fastq's)
  * Note: Running this instance costs ~10.00 AUD per hour, so pause the instance whenever bioinformatics pipelines are not running.
* Select key pair name (set up .ssh key with aws if none pre-existing)
* Allow SSH traffic from 'my IP'
* Configure storage
  * 5000GB (5TB) recommended for large pipelines
* Select IAM instance profile
  * Add EC2_S3_Write role to EC2 instance
* Click Launch instance

#### Connect to and set up EC2 instance
* Select the desired instance, and check details for Public IPv4 address
* SSH into instance using local Ubuntu
  ```bash
  ssh -i ~/.ssh/<key.pem> ubuntu@<Public IPv4 address>
  ```
* Update system packages

  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
* Download aws-cli
  ```bash
  sudo snap install aws-cli --classic
  ```

* Download the relevant fastq files from s3 or AGRF to codec-opensource/tmp/raw
  * Once files are downloaded to sysmed-seq-s3, the master snakefile will take care of downloads provided that the fastq folder is provided in the config.yaml
  * Note only 1 set of codec fastqs (R1 and R2) can be used per experimental pipeline currently.

### General setup (both local and EC2)

#### Set up github

* Generate GitHub SSH key (change to relevant email address):

  ```bash
  ssh-keygen -t ed25519 -C "user.lastname@systematicmedicine.com" -f ~/.ssh/EC2_git_key && \
  eval "$(ssh-agent -s)" && \
  ssh-add ~/.ssh/EC2_git_key && \
  cat ~/.ssh/EC2_git_key.pub
  ```
* Copy the key output and go to https://github.com/settings/keys  
* Click **New SSH key**  
* Title it (e.g. "EC2_git_key")  
* Paste the copied key and save
* Ensure github authentication works after restart (Make SSH agent start every time a shell session starts)

  ```bash
  nano ~/.bashrc
  ```
* Add the following lines to the end of ~/.bashrc

  eval "$(ssh-agent -s)" > /dev/null
  ssh-add ~/.ssh/EC2_git_key 2>/dev/null
  
* Save and exit (ctrl + o, ctrl + x)
* Reload shell

  ```bash
  source ~/.bashrc
  ```

#### Clone github repository
* Clone the GitHub repository:

  ```bash
  cd ~/project1 && \
  git clone git@github.com:systematicmedicine/codec-opensource.git
  ```

#### Modify config files
* config/ex_samples.csv (for codec samples):
  * The 'samples' column should only include the indices being used (must follow the indices naming system Sample01, Sample02, Sample03, Sample04 .. Sample12)
  * The 'samplename' column should match the actual samples being run to the sample indices used (e.g. buffycoat1.1, buffycoat1.2, buffycoat2.1, etc.)
  * Contamination data will be generated on any indices not included in this list.
* Modify config.yaml to match the number of cores on the system (e.g. increase to 96 cores if running on a 96 core EC2 instance). 
* Other file paths should not need to be modified, regardless of chosen repository name.

#### Activate tmux and docker
* Build docker

```bash
docker build -t codec .
```

* Set up a tmux session (in this example, the session is called pipeline, but it can be called anything)

  ```bash
  tmux new -s pipeline
  ```

* To exit the session without closing it (e.g. to use instance while the pipeline is running), type:
  * ctrl + b
  * d

* To access the tmux session later:
   
```bash
tmux attach -t pipeline
```
* In the tmux session, run docker:

```bash
docker run -it --rm -v ~/project1/codec-opensource:/work codec
```
## Running the Snakefile
  
* Run snakemake
  ```bash
  snakemake --configfile config/config.yaml --notemp
  ```
  * A list of additional useful snakemake commands:
  ```bash
  --notemp #Disables temporary files, meaning all files are saved and a run can be resumed if it crashes. This is useful during development.
  --dryrun #Pretends to run the snakemake, and outputs a list of what rules would have been run. This should typically always be run first to make sure the correct rules are being run and there are no errors. 
  --unlock #Unlocks snakemake after a failed run.
  --rerun-incomplete #Checks if any files are missing, incomplete or outdated (e.g. files from previous rules are newer) and re-runs them
  <rule-name> #Add the name of a rule at the end of the line to only run that rule (as well as any inputs required to run the rule)
  --stat #Gives a summary of time taken per rule and size of outputs.
  --configfile #Points to the config file (relative path config/config.yaml).
  -s #By default, no snakefile needs to be specified if snakefile is called 'Snakefile' and located in cwd. 
  ```
  #Example 1 (Dryrun)
  ```bash
  snakemake --configfile config/config.yaml --notemp --rerun-incomplete --dryrun
  ```
  #Example 2 (Run data, with stats output, but do not re-do steps that have already been completed)
  ```bash
  snakemake --configfile config/config.yaml --notemp --rerun-incomplete --cores all --stats runstats.json
  ```