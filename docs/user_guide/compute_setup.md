# Setting up compute platform

SomaticCODEC uses Docker-based containerisation to enable portability across computational platforms. In principle, the pipeline can be run on any Linux system with sufficient resources and Docker support.

Platform-specific configurations are defined using `environments`, which specify parameters such as thread and memory allocation.

`AWS m7i.48xlarge` instances have been routinely used to run the pipeline and provide a well-characterised, low-friction pathway for execution. Recommendations for using alternative platforms are also provided.

## AWS m7i.48xlarge setup

It is recommended to use a fresh AWS instance for each pipeline run to minimise the risk of carryover artefacts from previous executions.

1. Log into [AWS](https://aws.amazon.com/)

2. Navigate to EC2

3. Select *Launch instances*

4. Configure the instance
    - OS Image: Ubuntu Server 24.04 LTS
    - Instance type: m7i.48xlarge
    - Key pair: A key you have access to (or create new key pair) 
    - Allow SSH traffic: My IP
    - Configure storage: 
        - Volume type: gp3
        - Size: 500 GB free disk space per sample (EX and MS each)
        - IOPS: 8000
        - Throughput (MiB/s): 2000
    - IAM instance profile (optional): 
        - If staging files from S3, select a profile with access to the relevant bucket.

5. Connect to the instance
    - Copy the *Public IPv4 address* for the instance
    - Connect via SSH

    ```
    ssh -i ~/.ssh/<private_key>.pem ubuntu@<public_IPv4_address>
    ```

6. Clone the SomaticCODEC repository

    ```
    git clone https://github.com/systematicmedicine/SomaticCODEC.git
    ```

7. Install Docker

    ```
    curl -fsSL https://get.docker.com | sudo bash
    ```

8. Build Docker image

    ```
    cd SomaticCODEC
    sudo docker build -t codec-image .
    ```

## Other compute platforms

### Create environment config

Before using a different compute platform, ensure an environment configuration has been defined:
- If no environment exists, create one in the `/environments` directory.
- Each environment must contain an `environment.yaml` file
- Key parameters to configure include `infrastructure.memory` and `infrastructure.threads`. These parameters control resource allocation during pipeline execution.

### Installing SomaticCODEC

Follow the Docker installation, repository cloning, and image build steps described above.

### Recommended system resources

The resources required depend on:
- Number of samples
- Reads per sample
- Reference file size (e.g. genome)
- Desired runtime

For a typical use case (~2.5e8 reads per ex sample, 5.0e8 reads per ms sample), the following minimum resources are recommended:
- 500 GB free disk space per sample (EX and MS each)
- 32 threads
- 256 GB memory

It may be possible to run the pipeline with fewer resources, but testing will be required.









