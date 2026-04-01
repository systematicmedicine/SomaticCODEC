# Setting up compute platform

## Default platform (Amazon EC2)

The SomaticCODEC pipeline is optimised for execution on Amazon EC2. This is the recommended option for the smoothest setup and most predictable performance.

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
        - Size: 500 GiB per EX or MS sample
        - IOPS: 8000
        - Throughput (MiB/s): 2000
    - IAM instance profile: A profile with read access to the bucket where the sequencing data is stored, and write access to the bucket where the outputs will be uploaded

5. Connect to the instance
    - Copy the *Public IPv4 address* for the instance
    - Connect via SSH

    ```
    ssh -i ~/.ssh/<private_key>.pem ubuntu@<public_IPv4_address>
    ```

6. Install Docker

    ```
    curl -fsSL https://get.docker.com | sudo bash
    sudo usermod -aG docker "$USER" 
    ```

7. Clone the SomaticCODEC repository

    ```
    git clone https://github.com/systematicmedicine/SomaticCODEC.git
    ```

8. Build Docker image

    ```
    cd SomaticCODEC
    sudo docker build -t codec-image .
    ```

## Custom platform

While the pipeline has not been tested on other compute platforms, the containerised workflow and configurable infrastructure parameters should make it straightforward to run in alternative environments.

- Linux OS compatible with Docker

- Perform steps 6-8 from the Amazon EC2 instructions above

- For a batch of 12 samples (12 EX and 12 MS), it is recommended that the compute platform has at least:
    - 1.5x memory defined in `environment.yaml` -> `infrastructure.memory.extra_heavy`
    - 1.5x threads defined in `environment.yaml` -> `infrastructure.threads.heavy`
    - 12 TB free disk space

The resource parameters defined in `environments` -> `aws-m7i-48xlarge` -> `environment.yaml` are optimised for running batches of 12 samples (generated using the recommended library prep and sequencing parameters) on an EC2 `m7i.48xlarge` instance. If your context differs, consider creating a new `environment.yaml` with adjusted resource parameters.




