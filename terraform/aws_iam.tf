##########################################################################################
# IAM role for Bastion Host EC2 instance
##########################################################################################
resource "aws_iam_role" "bastion_ec2" {
  name = format(local.resource_name, "bastion-ec2-role")
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = format(local.resource_name, "bastion-profile")
  role = aws_iam_role.bastion_ec2.name
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_role_policy" {
  role       = aws_iam_role.bastion_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "rds_access" {
  name = format(local.resource_name, "rds-access-policy")
  role = aws_iam_role.bastion_ec2.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ],
        Resource = "*"
      }
    ]
  })
}
