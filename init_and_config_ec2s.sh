#!/bin/bash

TF_DIR="init-ec2s"
ANSIBLE_DIR="configure-ec2s"

cd $TF_DIR

# Init and Run Terraform apply
terraform init
terraform apply -auto-approve

# Export outputs to a JSON file
terraform output -json > "terraform_outputs.json"

cd ..

# Run python script that changes the hosts IP
python3 ./scripts/update_ansible_hosts_file.py 

# Run ansible playbook 
cd $ANSIBLE_DIR

ansible-playbook -i inventory/hosts.ini playbooks/configure_ec2s.yaml

cd ..
