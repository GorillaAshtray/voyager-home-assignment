provider "aws" {
  region = var.aws_region
}

locals {
  public_key = file("../.keys/id_rsa.pub")  # Specify the path to your public key file
}

resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = "ami-0583d8c7a9c35822c" # RHEL CentOS AMI
  instance_type = "t3.medium" # instance type (smallest type that still has enough resources to run minikube)

  key_name      = aws_key_pair.dev_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo useradd dev

              sudo mkdir -p /home/dev/.ssh
              sudo chown dev:dev /home/dev/.ssh
              sudo chmod 700 /home/dev/.ssh

              echo '${local.public_key}' | sudo tee -a /home/dev/.ssh/authorized_keys
              sudo chown dev:dev /home/dev/.ssh/authorized_keys

              sudo mkfs -t ext4 /dev/xvdf  
              sudo mkfs -t ext4 /dev/xvdg

              sudo mkdir -p /data /data1
              sudo mount /dev/xvdf /data
              sudo mount /dev/xvdg /data1
              echo '/dev/xvdf /data ext4 defaults 0 0' | sudo tee -a /etc/fstab
              echo '/dev/xvdg /data1 ext4 defaults 0 0' | sudo tee -a /etc/fstab
              EOF

  tags = {
    Name = "dev-ec2-instance-${count.index}"
  }
}

resource "aws_ebs_volume" "volume_data" {
  count = 2
  size  = 1 # 1 GB
  availability_zone = element(aws_instance.ec2_instances.*.availability_zone, count.index)
}

resource "aws_ebs_volume" "volume_data1" {
  count = 2
  size  = 1
  availability_zone = element(aws_instance.ec2_instances.*.availability_zone, count.index)
}

# Attach volumes to the instances
resource "aws_volume_attachment" "data_attachment" {
  count = 2
  device_name = "/dev/xvdf"
  instance_id = element(aws_instance.ec2_instances.*.id, count.index)
  volume_id   = element(aws_ebs_volume.volume_data.*.id, count.index)
}

resource "aws_volume_attachment" "data1_attachment" {
  count = 2
  device_name = "/dev/xvdg"
  instance_id = element(aws_instance.ec2_instances.*.id, count.index)
  volume_id   = element(aws_ebs_volume.volume_data1.*.id, count.index)
}

resource "aws_eip" "elastic_ip" {
  count = 2
  instance = element(aws_instance.ec2_instances.*.id, count.index)
}

resource "aws_key_pair" "dev_key" {
  key_name   = "dev-key"
  public_key = file("../.keys/id_rsa.pub") # Path to SSH public key
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to all IPs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach security group to EC2 instances
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  count             = 2
  security_group_id = aws_security_group.allow_ssh.id
  network_interface_id = element(aws_instance.ec2_instances.*.primary_network_interface_id, count.index)
}

output "elastic_ips" {
  value = aws_eip.elastic_ip.*.public_ip
}
