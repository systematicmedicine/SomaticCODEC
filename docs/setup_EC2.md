# setup_EC2.md

Instuctions for setting up codec-opensource pipeline on Amazon EC2


## Setup on Amazon EC2

### Launch EC2 instance

* Log into AWS
* Navigate to EC2
* Select <i>Launch instances</I>
* Configure the instance
    * OS Image: Ubuntu 24.04 LTS
    * Instance type: m6i.32xlarge (small runs), m6i.32xlarge (large runs)
    * Key pair: A key you have access to (or create new key pair) 
    * Allow SSH traffic: My IP
    * Configure storage: 16000GiB gp3
    * IAM instance profile: EC2_S3_Write
* Connect to the instance
    * navigate to EC2 > Instances
    * In the list of instances, right click on your instance and select <I>connect</I>
    * Select <I>SSH client</I>
    * Use your prefered SSH client to connect (e.g. SSH in WSL/Linux, Putty in Windows)


### Install required tools
```
sudo apt-get update
sudo apt-get install -y unzip

# Install AWS-CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install

# Install Docker
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker "$USER"
```
### Clone the codec-opensource repository
```
# Download deploy key
aws s3 cp s3://sysmed-ref-s3/keys/codec-opensource-deploy-key/codec-opensource-deploy-key ~/.ssh/codec-opensource-deploy-key
chmod 600 ~/.ssh/codec-opensource-deploy-key

# Clone repository
GIT_SSH_COMMAND='ssh -i ~/.ssh/codec-opensource-deploy-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new' \
git clone --branch dev git@github.com:systematicmedicine/codec-opensource.git
```

### Build Docker image
```
# Enter repoistory directory 
cd codec-opensource

# Build Docker image from Dockerfile
sudo docker build -t codec-image .
```

