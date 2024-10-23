# Voyager Home Assignment    

## How to Run the Project

1. **Clone the repository**
   `git clone git@github.com:GorillaAshtray/voyager-home-assignment.git`

2. **Generate a pair of SSH keys**  
   Use the `ssh-keygen` command to create a pair of SSH keys in the `.keys` directory, naming them `id_rsa`. This step is important because the automation trusts that the SSH keypair is stored in that directory.  
   The path that should be entered when prompted is:  
   `./.keys/id_rsa` (the full path might be needed)

3. **Initialize the services on AWS using Terraform**  
   The Terraform files are stored in the `init_ec2s` folder.

   `cd ./init_ec2s`  
   `terraform init`  
   `terraform apply -auto-approve`  
   `terraform output -json > "terraform_outputs.json"`  
   `cd ..`

   After running these commands, you should have all the services up and running on AWS.

4. **Configure EC2s on AWS using Ansible**  

   Before running the actual Ansible playbook, you need to run the `update_ansible_hosts_file.py` script using Python 3. This script ensures that the `hosts.ini` file is updated according to the new public IPs of the EC2 instances.

   To run the script:

   `python3 ./scripts/update_ansible_hosts_file.py`

   Afterwards, you can use Ansible freely to configure your instances:

   `cd ./configure_ec2s`  
   `ansible-playbook -i inventory/hosts.ini playbooks/configure_ec2s.yaml`  
   `cd ..`

   Alternatively, to initialize and configure the AWS services in one fell swoop, run the following from the root of the repository:

   `chmod u+x ./init_and_config_ec2s.sh`  
   `./init_and_config_ec2s.sh`

5. **To take a snapshot of an EBS volume, run the following:**

   `python3 ./scripts/snapshot_ec2.py SNAPSHOT_NAME VOLUME_ID MAXIMUM_SNAPSHOT_OF_VOL_ID`

6. **To deploy an Apache server to one of the nodes**:  
   First, you need to install Minikube on it. Pick a random node and proceed to SSH into it, remembering to use the private key in the `.keys` directory:

   `ssh -i ./.keys/id_rsa ec2-user@10.11.12.13`

   Afterwards, run the following command inside the node to install Minikube:

   `./scripts/install_minikube.sh`

   Then, copy the contents of the `./apache-kubernetes` directory into the node and apply the deployment and service files to the node:

   `kubectl apply -f ./apache-kubernetes/apache-deployment.yaml`  
   `kubectl apply -f ./apache-kubernetes/apache-service.yaml`

   Find out the node's IP address and port of the Apache server:

   `minikube ip`
