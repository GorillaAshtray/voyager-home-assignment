#!/bin/bash

# Run Terraform apply
terraform apply -auto-approve

# Export outputs to a JSON file
terraform output -json > terraform_outputs.json

# Run python script that changes the hosts IP
python3 update_hosts.py

# Run ansible playbook 


