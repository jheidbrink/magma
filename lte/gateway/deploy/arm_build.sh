#!/usr/bin/env bash

set -euo pipefail

SSH_KEY_FILE=${SSH_KEY_FILE:-~/.ssh/id_rsa}
MAGMA_BRANCH=${MAGMA_BRANCH:-master}
export AWS_REGION=${AWS_REGION:-us-east-1}

# --- will be configured by launch template github_actions_ec2_instances: ---
ssh_host_rsa_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOCQ2Tm8BRzQ+iqpBz4HFo6Ua4UWlYUmpIwWdwah3IzV4OUmN29jxcu4W93wS1hk01jmFNR2XNQSqSpfcVlCtsaVT8pd3kcAe7YEw2R0lLbaHPIALRhl/HqicuWKISFB357vSRy+Bqqw/H0MNm1KFwfIgBseL2X5Cjh8Ftn78EDhf8VRCj5Rt2ZF5hAX+eJyHEhX5htCtc5R3k4tRnWYwD2Jy9L+J2nHq6t96XdweKTwFLQaxPHTliXcJ4Ox6ku26g6j3BPc9rXvrfNfCYASeEbKF2rmhZ4cpd3XlXjYceiZAunlqcLSMBqMWdrKX66mJxJphsuZpKlVruJhJUOit4rHLMVb6B1Epd5ewcZjQO7w2XOcGJVGSzUUUkN7Hk4DMFpRzeTnolVXFiaaQg5RRC3ZJLCLtUW1MAKDNyQaUl6Q5y80gAVs/Dipx0l6zRxoONXScikTBbMHOJp9flB8++z8iixN48/L6CPe1EOOcVuU7P5PboKpLJFF1f8s1RZyjSJty6/v/7oy/nm+YJ/1nn7MI69KlyaU/SIOxJYUE7yr0l77sC/4HVhKrgiy/yqeXXNHCXRYoYtafAcGg5gAqRl8tkN0xBL+x8/G19B/k6ULf+iSc3nFgPBUa1NW4uFcCjyWjkhqdnnXYkiat91Mvsr7r+UrRYOVpCzDKS5vTr5w=="
ssh_port=2345
# --- end of launch-template settings ---

#echo "Searching for launch template github_actions_ec2_instances"
#launch_template_id=$(
#  aws ec2 describe-launch-templates \
#    --launch-template-names "github_actions_ec2_instances" \
#      | jq --raw-output '.LaunchTemplates[0].LaunchTemplateId'
#)
#echo "Found launch template $launch_template_id"

echo "Searching for AMI ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20220810"
ami_id=$(
  aws ec2 describe-images \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20220810" \
    | jq --raw-output '.Images[0].ImageId'
)
echo "Found AMI $ami_id"

echo "Launching instance"
aws ec2 run-instances \
    --launch-template LaunchTemplateName="github_actions_ec2_instances" \
    --instance-type t4g.medium \
    --image-id "$ami_id" \
    --ebs-optimized \
    --block-device-mapping '[ { "DeviceName": "/dev/sda1", "Ebs": { "VolumeSize": 50 } } ]' \
    > run-instances.json

instance_id=$(jq --raw-output '.Instances[0].InstanceId' < run-instances.json)
echo "Instance $instance_id launched."

echo "Waiting for association of public IP"
public_ip=""
until [[ "$public_ip" =~ [0-9].* ]]  # before a public IP is associated, it will be "" or "null"
do
    sleep 3
    public_ip=$(
      aws ec2 describe-instances --instance-ids "$instance_id" \
        | jq --raw-output '.Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp'
    )
done
echo "Public IP is $public_ip"

echo "Preparing SSH"
touch ~/.ssh/known_hosts && chmod go-rwx ~/.ssh/known_hosts
echo "[$public_ip]:$ssh_port $ssh_host_rsa_key" >> ~/.ssh/known_hosts
ssh_command="ssh -p $ssh_port -i $SSH_KEY_FILE -o ServerAliveInterval=60 ubuntu@$public_ip"
echo "The ssh command is: $ssh_command"

echo "Waiting for customized SSH server to come up"
until $ssh_command sleep 0
do
    sleep 5
done
echo "SSH server is up and running"

echo "deactivating short safety shutdown and activating safety shutdown in 4 hours"
$ssh_command "sudo shutdown -c && sudo shutdown -h 240"

echo "Installing packages"
$ssh_command <<EOT
sudo apt update
sudo apt install --assume-yes --no-install-recommends \
  docker.io \
  git \
  apt-transport-https \
  curl \
  gnupg \
  jq
EOT

echo "Adding ubuntu user to docker group"
$ssh_command sudo usermod --groups docker --append ubuntu

echo "Installing docker-compose"
$ssh_command <<EOT
sudo curl -L "https://github.com/docker/compose/releases/download/v2.10.2/docker-compose-Linux-aarch64" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
EOT

echo "Cloning magma repository"
$ssh_command "git clone --branch $MAGMA_BRANCH --depth 1 https://github.com/magma/magma.git"

echo "Building the containers"
$ssh_command <<EOT
cd magma/lte/gateway/docker
export IMAGE_VERSION=$(git rev-parse HEAD)
docker-compose build --build-arg CPU_ARCH=aarch64 --build-arg DEB_PORT=arm64
EOT
