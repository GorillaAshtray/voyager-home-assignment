#!/bin/bash

# Automatic bash script that runs the ansible part of the assignment (configuring the ec2 instances)

ANSIBLE_DIR="./configure-ec2s"
UPDATE_ANSIBLE_HOSTS_SCRIPT_PATH="./scripts/update_ansible_hosts_file.py"

# Check the Python script exists
if [ -f "$UPDATE_ANSIBLE_HOSTS_SCRIPT_PATH" ]; then
    python3 "$UPDATE_ANSIBLE_HOSTS_SCRIPT_PATH"   # Run the Python script that changes the IP addresses in the hosts.ini file

else
    echo "Error: Python script $PYTHON_SCRIPT does not exist."
    exit 1
fi

# Check if the Ansible directory exists
if [ -d "$ANSIBLE_DIR" ]; then
    cd "$ANSIBLE_DIR" 
    ansible-playbook -i inventory/hosts.ini playbooks/configure_ec2s.yaml  # run playbook with the hosts.ini file as the inventory
    cd ..  # Return to previous directory
else
    echo "Error: Directory $ANSIBLE_DIR does not exist."
    exit 1
fi