# setup_EC2.md

Instuctions for setting up codec-opensource pipeline on Amazon EC2


## Setup on Amazon EC2

### Launch EC2 instance

* Log into AWS
* Navigate to EC2
* Select <i>Launch instances</I>
* Configure the instance
    * OS Image: Ubuntu 24.04 LTS
    * Instance type: 
        * 1-2 EX/MS sample pairs: m6i.32xlarge
        * 3+ EX/MS sample pairs: m7i.48xlarge
    * Key pair: A key you have access to (or create new key pair) 
    * Allow SSH traffic: My IP
    * Configure storage: 
        * Volume type: gp3
        * Size (GiB): 1000 per EX or MS sample
        * IOPS: 8000
        * Throughput (MiB/s): 2000
    * IAM instance profile: EC2_S3_Write
* Connect to the instance
    * navigate to EC2 > Instances
    * In the list of instances, right click on your instance and select <I>connect</I>
    * Select <I>SSH client</I>
    * Use your prefered SSH client to connect (e.g. SSH in WSL/Linux, Putty in Windows)


### Setup environment
```
# Install required tools

sudo apt-get update
sudo apt-get install -y unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install

curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker "$USER"

# Clone codec-opensource repository

aws s3 cp s3://sm-unrestricted-team-a/key/codec-opensource-deploy-key/codec-opensource-deploy-key ~/.ssh/codec-opensource-deploy-key
chmod 600 ~/.ssh/codec-opensource-deploy-key

GIT_SSH_COMMAND='ssh -i ~/.ssh/codec-opensource-deploy-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new' \
git clone --branch master git@github.com:systematicmedicine/SomaticCODEC.git


# Build Docker image

cd SomaticCODEC
sudo docker build -t codec-image .
```

