# Voyager Home Assignment    

## How to Run the Project

## Prerequisites:



1. **Clone the repository**
   
   `git clone https://github.com/GorillaAshtray/voyager-home-assignment.git`

2. **Generate a pair of SSH keys**  
   Use the `ssh-keygen` command to create a pair of SSH keys in the `.keys` directory, naming them `id_rsa`. This step is important because the automation trusts that the SSH keypair is stored in that directory.  
   The path that should be entered when prompted is:  
   `./.keys/id_rsa` (the full path might be needed)

3. **Initialize the services on AWS using Terraform**  
   The Terraform files are stored in the `init-ec2s` folder.

   To initialize the ec2s using terraform, you can run the `run_terraform.sh` script:

   `./run_terraform` from the root of the repo

   Alternatively:

   `cd ./init_ec2s`
   `terraform init` 
   `terraform apply -auto-approve` (you will be prompted to put in your public key as a CLI argument)
   `terraform output -json > "terraform_outputs.json"`
   `cd ..`


   After running these commands, you should have all the services up and running on AWS.

5. **Configure EC2s on AWS using Ansible**  

   To configure the ec2s using ansible, you can run the `run_ansible.sh` script:

   `./run_ansible.sh` from the root of the repo


   Alternatively:

   Before running the actual Ansible playbook, the `update_ansible_hosts_file.py` script needs to be executed. This script ensures that the `hosts.ini` file is updated according to the new public IPs of the EC2 instances.

   `python3 ./scripts/update_ansible_hosts_file.py` 

   `cd ./configure-ec2s`  
   `ansible-playbook -i inventory/hosts.ini playbooks/configure_ec2s.yaml`  
   `cd ..`


6. **To take a snapshot of an EBS volume, run the following:**

   `python3 ./scripts/snapshot_ec2.py SNAPSHOT_NAME VOLUME_ID MAXIMUM_SNAPSHOT_OF_VOL_ID`

7. **To deploy an Apache server to one of the nodes**:  
   First, you need to install Minikube on it. Pick a random node and proceed to SCP the minikube installation script, remembering to use the private key in the `.keys` directory:

   `scp -i ./.keys/id_rsa ./scripts/install_minikube.sh ec2-user@NODE_IP:/home/ec2-user`

   Now, you will need to SCP the apache-server deployment and service files:

   `scp -r -i ./.keys/id_rsa ./apache-kubernetes ec2-user@NODE_IP:/home/ec2-user`


   Afterwards, ssh into the node and run the following commands inside the node to install minikube:

   `ssh -i ./.keys/id_rsa ec2-user@NODE_IP`
   
   `cd /home/ec2-user`  
   `chmod u+x install_minikube.sh`  
   `./install_minikube.sh`

   Then start the cluster:
   
   `minikube start --driver=docker`
   
   `alias kubectl="minikube kubectl --"`
   

   Then, apply the apache server deplyoment and service files:

   `kubectl apply -f ./apache-kubernetes/apache-deployment.yaml`  
   `kubectl apply -f ./apache-kubernetes/apache-service.yaml`

   Find out the node's IP address and port of the Apache server:

   `minikube ip`
   
   `kubectl get svc`

   Now curl to the apache server from the ec2-user terminal:
   
   `curl http://NODE_IP:NODE_PORT`

   You should get:
   
   `<html><body><h1>It works!</h1></body></html>`
