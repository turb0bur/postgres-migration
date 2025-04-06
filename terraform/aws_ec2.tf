##########################################################################################
# Bastion Host Resources
##########################################################################################
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_bastion.id
  instance_type          = var.bastion_host_config.instance_type
  subnet_id              = aws_subnet.public["subnet1"].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  user_data = base64encode(
    templatefile("${path.module}/templates/bastion_host_user_data.sh.tftpl", {})
  )

  root_block_device {
    volume_type           = var.bastion_host_config.ebs_volume.type
    volume_size           = var.bastion_host_config.ebs_volume.size
    delete_on_termination = var.bastion_host_config.ebs_volume.delete_on_termination
  }

  tags = {
    Name = format(local.resource_name, "bastion-host")
  }
}
