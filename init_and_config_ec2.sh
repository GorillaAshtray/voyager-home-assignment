#!/bin/bash

# Run Terraform apply
terraform apply -auto-approve

# Export outputs to a JSON file
terraform output -json > terraform_outputs.json

# Run python script that changes the hosts IP
python3 ./scripts/update_hosts.py

# Run ansible playbook 
ansible-playbook -i configure-ec2s/inventory/hosts.ini configure-ec2s/playbooks/configure_ec2s.yaml