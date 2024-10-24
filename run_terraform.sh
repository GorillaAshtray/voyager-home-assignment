#!/bin/bash

# Automatic bash script that runs the terraform part of the assignment

TF_DIR="init-ec2s"

cd $TF_DIR # cd into the TF directory
terraform init 
terraform apply -auto-approve
terraform output -json > "terraform_outputs.json"  # export outputs to a JSON file for update_ansible_hosts_file.py script
cd ..