#!/usr/bin/env bash

set -euo pipefail

SSH_KEY_FILE=${SSH_KEY_FILE:-~/.ssh/id_rsa}
MAGMA_BRANCH=${MAGMA_BRANCH:-master}
MAGMA_REPO_URL=${MAGMA_REPO_URL:-https://github.com/magma/magma.git}
export AWS_REGION=${AWS_REGION:-us-east-1}

# --- will be configured by launch template github_actions_ec2_instances: ---
ssh_host_rsa_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8nDOX2vSuTNhURvTdAIz4uhnHMkuMmyskUPh37C1arPG5t/83vSLWSqonQBWGXJ4mhfzE5BHcJT8RaIrHXDZ/wQWxPFVG0ZE8iKPdNdsj/IXMew+xuQ/qo9naW7efI/6BpaJtoqPDQD/5YDJXUW2iq7COW9AfIV4euQlrHduE2DLsTgx+bis2AmyP74ZaFMZLKfOwEqksLNCXk/T7EDBU15f00Blmdd7l1+xEeJp+uwHyWGNJE9kkuLNmxz6HAcLTnw2WBmUsRtuHMGFS4OOthMYZvmEAPXPk03bdMSEJ5JUk4eo9Wzf7vlvkaUHCVw59cPkU6HUctcm5+6cxA34bLhop1wfYzm4Zy3bDrRoiBzJ7gdxo9njlh8L6yjFWLyK+YHZm+1nGb9VbIJLosWtQwiTeMHqqAol/y6UySbVuZ9hny4ESKtYLiwgFRxkK+RAyvhUt7EDz7lhzSQdznuDfHOxkQSl0vJOo1T/6PPQ6v1ixCwf3DQ+41GjvJ3j2bIyV7/JQrJuzM9pMBX3hDD3hoH7GS914J4xIVFznnXdUrcCKCxPq6W63uykf4p8bQ/LSNwUXvdzTHJEi21jyN/rgakgkVD/bO4uzRppkm8pBMuF+X2miI+dV07uP4EkyInLcwDqc2Q0CymtYyTWKvZTQwnedAO+67HJu5Z+/WXt+dQ=="
ssh_port=2345
# --- end of launch-template settings ---

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

echo "Registering exit trap to terminate instance"
function terminate_instance() {
    echo "Sleeping 30 minutes before terminating the instance"
    sleep 30m
    echo "Terminating instance $instance_id"
    aws ec2 terminate-instance --instance-ids "$instance_id"
}
trap terminate_instance EXIT

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

echo "Cloning magma repository ${MAGMA_REPO_URL}:${MAGMA_BRANCH}"
$ssh_command "git clone --branch $MAGMA_BRANCH --depth 1 $MAGMA_REPO_URL"

echo "Building the containers"
$ssh_command <<EOT
cd magma/lte/gateway/docker
export IMAGE_VERSION=$(git rev-parse HEAD)
docker-compose build --build-arg CPU_ARCH=aarch64 --build-arg DEB_PORT=arm64
EOT
