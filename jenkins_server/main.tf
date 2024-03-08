# Provide configuration
provider "aws" {
  region = "us-east-1"
}

#Set up your user access key ID and secret access key for terraform to connect to AWS Console
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

#create a vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins-vpc"
  }
}

#create subnet
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "jenkins-Subnet"
    Type = "Public"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "jenkins-igw"
  }
}

#Create a Route Table
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public"
  }
}

#Associate the Subnet with the Route Table
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt1.id
}

# create security group
resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and HTTP Traffic"
  vpc_id      = aws_vpc.main.id

 # allowing traffic from our IP on port 22
  ingress {
    description = "incoming SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # to be able ot access the EC2 instance on port 8080
  ingress {
    description = "incoming HTTP traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "incoming 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 # Jenkins EC2 instance to being able to talk to the internet

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # We are setting the Name tag to jenkins_sg
  tags = {
    "Name" = "jenkins-sg"
  }
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# create aws resource
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  associate_public_ip_address = true
  # Go to AWS console under EC2 Network and security and create a PEM Key pair and replace my Key_name with your key pair name. 
  key_name                    = "jenkins-coding-challenge"

  tags = {
    "Name" = "Jenkins"
  }

}


# an empty resource block
resource "null_resource" "jenkins" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    port        = "22"
    # I used the default username, ec2-user. However, read your AMI usage instructions to check if the AMI owner has changed your default AMI username.
    user        = "ec2-user"
    # Enter the path to where you saved the key pair you created/downloaded before and add .pem 
    private_key = file("~/Downloads/jenkins-coding-challenge.pem")
    host        = aws_instance.jenkins.public_ip
    agent       = false
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh",
    ]
  }


  # wait for ec2 to be created
  depends_on = [aws_instance.jenkins]
}

# print the url of the jenkins server
output "website_url" {
  value     = join ("", ["http://", aws_instance.jenkins.public_ip, ":", "8080"])
}

output "public_ip" {
   description = "The public IP address of the Jenkins server"
   value = aws_instance.jenkins.public_ip
}