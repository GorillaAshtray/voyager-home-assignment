#!/bin/bash

# Automatic bash script that runs the terraform part of the assignment (initializing the ec2 instances)

TF_DIR="./init-ec2s"

# Check if the Terraform directory exists
if [ -d "$TF_DIR" ]; then
    cd "$TF_DIR"
    terraform init 
    terraform apply -auto-approve
    terraform output -json > "terraform_outputs.json"  # export outputs to a JSON file for update_ansible_hosts_file.py script
    cd ..  # Return to the previous directory
else
    echo "Error: Directory $TF_DIR does not exist."
    exit 1
fi
