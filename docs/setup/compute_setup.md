# compute_setup.md

## Recommended (Amazon EC2)

1. Log into [AWS](https://aws.amazon.com/)

2.  Navigate to EC2

3. Select *Launch instances*

4. Configure the instance
    - OS Image: Ubuntu Server 24.04 LTS
    - Instance type: m7i.48xlarge
    - Key pair: A key you have access to (or create new key pair) 
    - Allow SSH traffic: My IP
    - Configure storage: 
        - Volume type: gp3
        - Size (GiB): 500 per EX or MS sample
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
    git clone git@github.com:systematicmedicine/SomaticCODEC.git
    ```

8. Build Docker image

    ```
    cd SomaticCODEC
    sudo docker build -t codec-image .
    ```

9. Start tmux session

    ```
    tmux new -s codec-session
    ```

10. Run docker container

    ```
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") && \
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id) && \
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d'"' -f4) && \
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    -e INSTANCE_ID="$INSTANCE_ID" \
    -e AWS_REGION="$REGION" \
    codec-image
    ```

## Custom
