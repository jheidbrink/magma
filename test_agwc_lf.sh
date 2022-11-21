#!/usr/bin/env bash

# This is basically creation of an EC2 instance plus https://docs.magmacore.org/docs/next/lte/deploy_install_docker plus modifications to use the new artifactory

set -euo pipefail

ARCHITECTURE=${ARCHITECTURE:-amd64}
SSH_KEY_FILE=${SSH_KEY_FILE:=~/.ssh/id_rsa_jan_tng_magmacore}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-linuxfoundation.jfrog.io/magma-docker-agw-prod}
IMAGE_VERSION=${IMAGE_VERSION:-latest}

export AWS_REGION=us-east-1
echo "Using region $AWS_REGION as required subnets and security groups are currently only deployed there."

if [[ $ARCHITECTURE = amd64 ]]
then
    ami_name=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20220810
    instance_type=${INSTANCE_TYPE:-m6a.2xlarge}
elif [[ $ARCHITECTURE = arm64 ]]
then
    ami_name=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20220810
    instance_type=${INSTANCE_TYPE:-m6gd.2xlarge}
else
    echo "Unknown architecture: $ARCHITECTURE. Choose between amd64 and arm64."
    exit 1
fi

public_subnet_id=$(
  aws ec2 describe-subnets \
      --filters "Name=tag:name,Values=public 1" \
    | jq -r '.Subnets[0].SubnetId'
)
echo "public subnet is is $public_subnet_id"

ssh_and_mosh_sg_id=$(
  aws ec2 describe-security-groups \
      --filters Name=group-name,Values=public_ssh_and_mosh \
    | jq -r '.SecurityGroups[0].GroupId'
)
echo "ssh_and_mosh security group id is $ssh_and_mosh_sg_id"

echo "Not creating public interface as that is done on the fly with the instance later"
#public_network_interface_id=$(
#  aws ec2 create-network-interface \
#      --subnet-id "$public_subnet_id" \
#      --groups "$ssh_and_mosh_sg_id" \
#    | jq -r '.NetworkInterface.NetworkInterfaceId'
#)
#echo "Public network interface id is $public_network_interface_id"

private_subnet_id=$(
  aws ec2 describe-subnets \
      --filters "Name=tag:name,Values=private 1" \
    | jq -r '.Subnets[0].SubnetId'
)
echo "private subnet is is $private_subnet_id"

private_network_interface_id=$(
  aws ec2 create-network-interface --subnet-id "$private_subnet_id" \
    | jq -r '.NetworkInterface.NetworkInterfaceId'
)
echo "private network interface id is $private_network_interface_id"

ami_id=$(
  aws ec2 describe-images \
    --filters "Name=name,Values=$ami_name" \
    | jq --raw-output '.Images[0].ImageId'
)


echo "Starting instance with AMI ${ami_id}"
#"DeviceIndex=1,SubnetId=$private_subnet_id"
instance_id=$(
  aws ec2 run-instances \
      --instance-type "$instance_type" \
      --image-id "$ami_id" \
      --launch-template LaunchTemplateName="public_ubuntu_instance_custom_host_keys_multiple_users" \
      --network-interfaces \
        "DeviceIndex=0,SubnetId=$public_subnet_id,Groups=$ssh_and_mosh_sg_id" \
      --ebs-optimized \
      --block-device-mapping '[ { "DeviceName": "/dev/sda1", "Ebs": { "VolumeSize": 50 } } ]' \
    | jq --raw-output '.Instances[0].InstanceId'
)
echo "Started instance ${instance_id}"

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

echo "Associating private network interface ${private_network_interface_id} with instance ${instance_id}"
aws ec2 attach-network-interface \
    --device-index 1 \
    --instance-id "$instance_id" \
    --network-interface-id "$private_network_interface_id"


echo "Preparing SSH"
touch ~/.ssh/known_hosts && chmod go-rwx ~/.ssh/known_hosts
echo "[$public_ip]:2345 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8nDOX2vSuTNhURvTdAIz4uhnHMkuMmyskUPh37C1arPG5t/83vSLWSqonQBWGXJ4mhfzE5BHcJT8RaIrHXDZ/wQWxPFVG0ZE8iKPdNdsj/IXMew+xuQ/qo9naW7efI/6BpaJtoqPDQD/5YDJXUW2iq7COW9AfIV4euQlrHduE2DLsTgx+bis2AmyP74ZaFMZLKfOwEqksLNCXk/T7EDBU15f00Blmdd7l1+xEeJp+uwHyWGNJE9kkuLNmxz6HAcLTnw2WBmUsRtuHMGFS4OOthMYZvmEAPXPk03bdMSEJ5JUk4eo9Wzf7vlvkaUHCVw59cPkU6HUctcm5+6cxA34bLhop1wfYzm4Zy3bDrRoiBzJ7gdxo9njlh8L6yjFWLyK+YHZm+1nGb9VbIJLosWtQwiTeMHqqAol/y6UySbVuZ9hny4ESKtYLiwgFRxkK+RAyvhUt7EDz7lhzSQdznuDfHOxkQSl0vJOo1T/6PPQ6v1ixCwf3DQ+41GjvJ3j2bIyV7/JQrJuzM9pMBX3hDD3hoH7GS914J4xIVFznnXdUrcCKCxPq6W63uykf4p8bQ/LSNwUXvdzTHJEi21jyN/rgakgkVD/bO4uzRppkm8pBMuF+X2miI+dV07uP4EkyInLcwDqc2Q0CymtYyTWKvZTQwnedAO+67HJu5Z+/WXt+dQ==" >> ~/.ssh/known_hosts
ssh_command="ssh -p 2345 -i $SSH_KEY_FILE -o ServerAliveInterval=60 ubuntu@$public_ip"
function print_ssh_command() {
    echo "The ssh command is: $ssh_command"
}
print_ssh_command

trap print_ssh_command EXIT

echo Waiting for SSH to come up
until $ssh_command echo ""
do
   sleep 3
done

echo "Stopping 10 minute shutdown timer that was set to protect the instance from accidentally lying around"
$ssh_command sudo shutdown -c
echo "Setting a new timer for 3 hours. If you need more time, you need to deactivate the shutdown."
$ssh_command sudo shutdown -h 180

echo "Copying rootCA.pem"
< "$MAGMA_ROOT/.cache/test_certs/rootCA.pem" $ssh_command sudo bash -c '"mkdir -p /var/opt/magma/certs && cat > /var/opt/magma/certs/rootCA.pem"'

$ssh_command <<EOT
wget https://github.com/jheidbrink/magma/raw/test_agwc_artifactory_switch/lte/gateway/deploy/agw_install_docker.sh
sudo bash agw_install_docker.sh
EOT

echo 'Assuming that we got to the "Reboot this VM to apply kernel settings" prompt'
$ssh_command sudo systemctl reboot

echo Waiting for SSH to come up
until $ssh_command echo ""
do
   sleep 3
done

echo Configuring .env
$ssh_command <<EOT
sudo chmod u+w /var/opt/magma/docker/.env
sudo sed -i \
  -e s@DOCKER_REGISTRY=.*@DOCKER_REGISTRY=${DOCKER_REGISTRY}/@ \
  -e s/IMAGE_VERSION=.*/IMAGE_VERSION=${IMAGE_VERSION}/ \
  /var/opt/magma/docker/.env
EOT

echo "Now you can cd /var/opt/magma/docker && sudo docker-compose up"
$ssh_command
