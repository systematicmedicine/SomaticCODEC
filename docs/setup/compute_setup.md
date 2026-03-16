# compute_setup.md

## Recommended (Amazon EC2)

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

## Custom

If using a different compute method or instance, ensure that:

- The chosen OS is compatible with the tools used by the pipeline

- The system resources available are sufficent, and the below parameters have been adjusted in config/config.yaml:
    - `infrastructure.memory`
    - `infrastructure.threads`
    - `infrastructure.create_run_timeline_plot.disk_iops`
    - `infrastructure.create_run_timeline_plot.disk_throughput`
