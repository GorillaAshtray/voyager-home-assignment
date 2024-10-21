provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instances" {
  count         = 2
  ami           = "ami-0583d8c7a9c35822c" # RHEL CentOS AMI
  instance_type = "t2.micro" # Small instance type

  key_name      = aws_key_pair.dev_key.key_name

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
  public_key = file("./keys/id_rsa.pub") # Path to SSH public key
}

# Use a provisioner to create 'dev' user and set up disk mounting
resource "null_resource" "create_dev_user" {
  count = 2
  triggers = {
    always_run = "${timestamp()}"  # Forces re-execution on every apply
  }

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      user        = "ec2-user" 
      private_key = file("./keys/id_rsa") # Path to your private key
      host        = element(aws_instance.ec2_instances.*.public_ip, count.index)
    }

    inline = [
      "sudo useradd dev",

      "sudo mkdir -p /home/dev/.ssh",
      "sudo chown dev:dev /home/dev/.ssh",
      "sudo chmod 700 /home/dev/.ssh",
      
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDS7/bMqGK6f0De8aAMU8fquPnnOLRu1/jQQiMyRdb1U7he+gOjGunvZcYA7DGUjGvHGom4mqR+yo8Qb+axzpgQlFZMKdAFnkSxhI/cTXEj40cbapB5AamuroSlQKJnIFw2B5ig5gqOnVw1rA9wykcpYa/iqPfwtSUwD9yQgoZ42J3OHMVZkgtJaNDXpf/dM7F3cbBwGFsor7DWB8LOcpt6jWUMhhYTuLYhbmKHOXMa1J4b/aFjEDvJM/LwP87IoV5PmSVy0ojBgWX5/GASydZyezdypEzghZm+BzR0+Pot559Kla2Lcy3ObIG8SySshWlySaLoMz14jkbee47jkNa1aqH3NfyUTXsalsXVUmpYj8Z9DBsA+wsXbLccf7OIZdSDakGZ5PdaZ/Fu+xggIN5wk4A9XvT49KyLEz9hdLFcB7QcZPi0JSE3fQ6T1Sq23NPsNypT/Dllu4YjTMnaIBX4cbEy5jUlTjpYMzQvFw9ymIbcfGyQ/qflI5OvPjOGN7S+5r7r+7/jNwsIdG5WXLjU1szyff6vrP3EP38I9VAMQ2YSyQUbvrqc+eqbplBCchZiL7NDOLzcQpKtkGS7oqlgwugB9dN1642D/1r09IGnXojRvCPt4o/7S93knlFARC2yXWhaTZsrKo9IqT1wem5PixLQD5PIf0iQGdl0/C8xfw== itayweiss321@gmail.com' | sudo tee -a /home/dev/.ssh/authorized_keys",
      "sudo chown dev:dev /home/dev/.ssh/authorized_keys",

      # Format the volumes before mounting
      "sudo mkfs -t ext4 /dev/xvdf",  # Format /dev/xvdf
      "sudo mkfs -t ext4 /dev/xvdg",  # Format /dev/xvdg

      "sudo mkdir -p /data /data1",
      "sudo mount /dev/xvdf /data",
      "sudo mount /dev/xvdg /data1",
      "echo '/dev/xvdf /data ext4 defaults 0 0' | sudo tee -a /etc/fstab",
      "echo '/dev/xvdg /data1 ext4 defaults 0 0' | sudo tee -a /etc/fstab"
    ]
  }
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

output "instance_public_ips" {
  value = aws_instance.ec2_instances.*.public_ip
}

output "elastic_ips" {
  value = aws_eip.elastic_ip.*.public_ip
}
