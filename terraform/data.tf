data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_bastion" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_caller_identity" "current" {}
