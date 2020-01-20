provider "aws" {
  region = "us-east-1"
  profile = "default"
  max_retries = 3
}

variable "AdminPassword" {
  type = string
}

locals {
  aws_ami_id = "ami-09d069a04349dc3cb"
}

resource "aws_instance" "factorio_server" {
  ami = local.aws_ami_id
  instance_type = "t3.medium"
  key_name = "factorioServer"
  security_groups = ["${aws_security_group.factorio_security_group.name}"]
  user_data = <<USER_DATA
  #!/bin/bash
  sudo yum update -y
  sudo yum install docker -y
  sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
  sudo chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose --version
  sudo yum install git -y
  git clone https://github.com/sdrafahl/FactorioServer.git
  cd FactorioServer
  cd factorio
  echo ${var.AdminPassword} > RCON.pw
  cd ..
  sudo service docker start
  sudo docker-compose up -d
  echo "Running Factorio Container"
  USER_DATA
}

data "aws_route53_zone" "primary" {
  name = "shanesfactorioserver.com"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "www.shanesfactorioserver.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.factorio_server.public_ip}"]
}

resource "aws_security_group" "factorio_security_group" {
  name        = "factorio_security_group"
  description = "Used to grant SSH and Factorio client to connect"
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
