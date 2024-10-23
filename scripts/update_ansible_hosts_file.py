import json
import os
import re

TF_DIR = "init-ec2s"
ANSIBLE_INVENTORY_DIR = "configure-ec2s/inventory"

output_file = f'{TF_DIR}/terraform_outputs.json'  # Path to the terraform output file
hosts_file = f'{ANSIBLE_INVENTORY_DIR}/hosts.ini'  # Path to the hosts.ini file

# Define variables before using them in try and except blocks
outputs = {}
existing_hosts = []  

# Load Terraform outputs
try:
    with open(output_file) as f:
        outputs = json.load(f)
except (FileNotFoundError, json.JSONDecodeError) as e:
    print(f"Error reading {output_file}: {e}")
    exit(1)

ec2_instance_ips = outputs.get('elastic_ips', {}).get('value', [])  # Get EC2 instance IPs

# Load the hosts.ini file
try:
    with open(hosts_file, 'r') as f:
        existing_hosts = f.readlines()
except IOError as e:
    print(f"Error reading {hosts_file}: {e}")
    exit(1)


hosts_content = ''.join(existing_hosts)  # Combine lines to a single string (necessary for the re module)

# Use regex to replace the IPs for ec2_instance_1 and ec2_instance_2
hosts_content = re.sub(r'(?<=ec2_instance_1 ansible_host=)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', ec2_instance_ips[0], hosts_content)
hosts_content = re.sub(r'(?<=ec2_instance_2 ansible_host=)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', ec2_instance_ips[1], hosts_content)

# Write the updated content back to the hosts.ini file
with open(hosts_file, 'w') as f:
    f.write(hosts_content)

print(f"Updated {hosts_file} with new EC2 instance IPs.")