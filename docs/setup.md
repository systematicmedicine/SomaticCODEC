# setup.md

Instuctions for setting up codec-opensource pipeline on a new device

## System requirements

Recommended:
* 96 CPU
* 384 GB RAM
* 5TB hard disk space
* Ubuntu Linux 22.04 LTS
* Git
* Docker

## Setup on Amazon EC2

### Launch EC2 instance

* Log into AWS
* Navigate to EC2
* Select <i>Launch instances</I>
* Configure the instance
    * OS Image: Ubuntu 22.04 LTS
    * Instance type: m6i.24xlarge
    * Key pair: A key you have access to (or create new key pair) 
    * Allow SSH traffic: My IP
    * Configure storage: 5000GiB gp3
    * IAM instance profile: If downloading data from S3, select an instance profile that gives you read only access (optional)
* Connect to the instance
    * navigate to EC2 > Instances
    * In the list of instances, right click on your instance and select <I>connect</I>
    * Select <I>SSH client</I>
    * Use your prefered SSH client to connect (e.g. ssh in WSL, putty in windows)
```
# Example ssh command in linux
ssh -i "myKey.pem" ubuntu@ec2-3-97-145-201.ap-southeast-2.compute.amazonaws.com
```

### Clone the codec-opensource repository
The repository deploy key can be found at `\RwoD Research\Personal\Cameron\Misc\codec-opensource deploy key`

```
# Create empty file using vim, and paste in key
vim ~/.ssh/deploy_key
# Update key permissions
chmod 600 ~/.ssh/deploy_key
# Add key to known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts
# Clone repo
GIT_SSH_COMMAND='ssh -i ~/.ssh/deploy_key' git clone --branch dev git@github.com:systematicmedicine/codec-opensource.git
# Change working directory
cd codec-opensource
```

### Setup docker
```
# Install docker
sudo snap install docker

# Build docker image from dockerfile
sudo docker build -t codec .
```

