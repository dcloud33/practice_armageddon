
########## Locals ########
locals {
    name_prefix = var.user_name
}

##################-VPC-#################


resource "aws_vpc" "help_me" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Please_Sweet_Mercy"
  }
}


###################-Subnets: Public & Private-#############


resource "aws_subnet" "sweet_freedom_public" {

  vpc_id                  = aws_vpc.help_me.id
  cidr_block              = "10.80.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "I_can_see_the_light!"
  }
}


resource "aws_subnet" "the_frozen_hell_of_hoath_private" {

  vpc_id            = aws_vpc.help_me.id
  cidr_block        = "10.80.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "I_lost_my_lightsaber_in_the_snow!"
  }
}

############## Internet gateway, Route Table, & Elastic IP ###############


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.help_me.id

  tags = {
    Name = "The gateway to freedom"
  }
}

resource "aws_eip" "mando_eip" {
  domain = "vpc"

  tags = {
    Name = "The_elasticity!"
  }
}

resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.mando_eip.id
  subnet_id     = aws_subnet.sweet_freedom_public.id # NAT in a public subnet

  tags = {
    Name = "My_underground_connection!"
  }

  depends_on = [aws_internet_gateway.igw]
}

############ Route Tables: Public & Private #############



resource "aws_route_table" "gateway_to_freedom_public_rt" {
  vpc_id = aws_vpc.help_me.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "My_public_route_table"
  }
}




resource "aws_route_table_association" "yay_public_route_table_association" {
  subnet_id      = aws_subnet.sweet_freedom_public.id
  route_table_id = aws_route_table.gateway_to_freedom_public_rt.id
}


resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.help_me.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat.id
  }

  tags = {
    Name = "closedoff-private-route_table"
  }
}

resource "aws_route_table_association" "yay_private_route_table_association" {
  subnet_id      = aws_subnet.the_frozen_hell_of_hoath_private.id
  route_table_id = aws_route_table.my_private_route_table.id
}


####################### Security Groups: EC2 & RDS #################################
resource "aws_security_group" "my-ec2-sg" {
  name        = "my-ec2-sg"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.help_me.id

  tags = {
    Name = "my-ec2-sg01"
  }
}

########################## Security Group Ingress & Egress Rules for EC2 ######################
resource "aws_vpc_security_group_ingress_rule" "http_access" {
  security_group_id = aws_security_group.my-ec2-sg.id
  cidr_ipv4         = aws_vpc.help_me.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.my-ec2-sg.id
  cidr_ipv4         = aws_vpc.help_me.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.my-ec2-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################### RDS Security Group: Ingress & Egress ######################

resource "aws_security_group" "my-rds-sg" {
  name        = "my-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.help_me.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group.chewbacca_ec2_sg01.id

  tags = {
    Name = "my-rds-sg01"
  }
}

resource "aws_security_group_rule" "ec2_to_rds_access" {
  type                     = "ingress"
  security_group_id        = aws_security_group.my-rds-sg.id
  cidr_blocks              = [aws_vpc.help_me.cidr_block]
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  source_security_group_id = aws_security_group.my-ec2-sg.id
}

resource "aws_vpc_security_group_egress_rule" "rds_outbound" {
  security_group_id = aws_security_group.my-rds-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}



##################-RDS Subnet Group-#######################################


resource "aws_db_subnet_group" "my_rds_subnet_group" {
  name        = "my-rds-subnet-group"
  subnet_ids  = aws_subnet.the_frozen_hell_of_hoath_private[*].id
  description = "this will have the RDS in the private subnet"

  tags = {
    Name = "my-rds-subnet-group"
  }
}


################ RDS Instance: MySQL ###################


resource "aws_db_instance" "my_instance_rds" {
  identifier             = "lab-mysql"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.rds_db_name
  username               = var.rds_user_name
  password               = var.rds_db_password

  db_subnet_group_name   = aws_db_subnet_group.my_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.my-rds-sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true

  # TODO: student sets multi_az / backups / monitoring as stretch goals

  tags = {
    Name = "my-rds-instance"
  }
}


################## IAM Role & EC2 Instance #####################

# Explanation: Chewbacca refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "my_ec2_role" {
  name = "my-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are your Wookiee toolbelt—tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "my_ec2_ssm_attach" {
  role       = aws_iam_role.my_ec2_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "my_ec2_secrets_attach" {
  role      = aws_iam_role.my_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
}


resource "aws_iam_role_policy" "specific_access_policy" {
  name = "SecretsManagerReadWrite"
  role = aws_iam_role.my_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:secretmanager:${var.aws_region}::secret:${local.name_prefix}/rds/mysql*"
          
        ]
      }
    ]
  })
}


# This will be used in conjunction with the ec2 instance
resource "aws_iam_instance_profile" "my_instance_profile" {
  name = "my-instance-profile01"
  role = aws_iam_role.my_ec2_role.name
}

############ EC2 Instance: App Host ##################################

resource "aws_instance" "my_created_ec2"{
  ami                     = var.ec2_ami_id
  instance_type           = var.ec2_instance_type
  subnet_id               = aws_subnet.sweet_freedom_public.id
  vpc_security_group_ids  = [aws_security_group.my-ec2-sg.id]
  iam_instance_profile    = aws_iam_instance_profile.my_instance_profile.name

  user_data = file("user_data/user_data.sh")

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}



############ Secrets Manager: DB Credentials #####################


resource "aws_secretsmanager_secret" "my_db_secret" {
  name = "${local.name_prefix}/rds/mysql"
}

resource "aws_secretsmanager_secret_version" "my_db_secret_version" {
  secret_id = aws_secretsmanager_secret.my_db_secret.id

  secret_string = jsonencode({
    username = var.rds_user_name
    password = var.rds_db_password
    host     = aws_db_instance.my_instance_rds.address
    port     = aws_db_instance.my_instance_rds.port
    dbname   = var.rds_db_name
  })
}
