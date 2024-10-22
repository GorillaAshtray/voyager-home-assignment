import json
import os

TF_DIR="init-ec2s"
ANSIBLE_INVENTORY_DIR="configure-ec2s/inventory"

output_file = f'{TF_DIR}/terraform_outputs.json' # Path to the Terraform output file
hosts_file = f'{ANSIBLE_INVENTORY_DIR}/hosts.ini' # Path to the hosts.ini file

# Load Terraform outputs
try:
    with open(output_file) as f:
        outputs = json.load(f)
except (FileNotFoundError, json.JSONDecodeError) as e:
    print(f"Error reading {output_file}: {e}")
    exit(1)

# Get EC2 instance IPs
ec2_instance_ips = outputs.get('elastic_ips', {}).get('value', [])

# Check if there are enough IPs
if len(ec2_instance_ips) < 2:
    print("Not enough IPs available to update the hosts file.")
    exit(1)

# Prepare new hosts entries with the correct ansible hosts file format
new_hosts_entries = [
    f"ec2_instance_1 ansible_host={ec2_instance_ips[0]}\n",
    f"ec2_instance_2 ansible_host={ec2_instance_ips[1]}\n"
]

# Read existing hosts.ini
if os.path.exists(hosts_file):
    with open(hosts_file, 'r') as f:
        existing_hosts = f.readlines()
else:
    existing_hosts = []

# Update the hosts.ini file
updated_hosts = []
in_ec2_section = False

for line in existing_hosts:
    # If we enter the [ec2_instances] section
    if line.strip() == "[ec2_instances]":
        in_ec2_section = True
        updated_hosts.append(line)  # Add the section header
        updated_hosts.extend(new_hosts_entries)  # Add new entries
        continue  # Skip to the next line

    # If we exit the [ec2_instances] section
    if in_ec2_section:
        if line.strip() == "":  # Empty line indicates end of section
            in_ec2_section = False
            updated_hosts.append(line)  # Add the empty line back
            continue
        # Skip over old entries in the [ec2_instances] section
        continue

    # For lines outside the [ec2_instances] section
    updated_hosts.append(line)

# Write the updated hosts back to the file
with open(hosts_file, 'w') as f:
    f.writelines(updated_hosts)

print(f"Updated {hosts_file} with new EC2 instance entries.")
