#!/bin/bash

# Automatic bash script that runs the ansible part of the assignment

ANSIBLE_DIR="configure-ec2s"

python3 ./scripts/update_ansible_hosts_file.py  # Run python script that changes the ip addresses in the hosts.ini file

cd $ANSIBLE_DIR  # cd into the ansible directory 
ansible-playbook -i inventory/hosts.ini playbooks/configure_ec2s.yaml  # run playbook with the hosts.ini file as the inventory
cd ..