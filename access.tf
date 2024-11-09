resource "aws_key_pair" "admin" {
  key_name   = "sandbox-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "ssh_from_home" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.home_address
    description = "from home"
  }

  tags = {
    Name = "ssh_from_home"
  }
}

variable "ssh_public_key" {
  type = string
  description = "ssh public key which will be added to EC2"
}

variable "home_address" {
  type = list(string)
  description = "ip address of my home - ssh will be allowed from this address"
}
