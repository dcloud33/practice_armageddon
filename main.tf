
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


###################-SUBNETS FOR PUBLIC & PRIVATE-############################


resource "aws_subnet" "sweet_freedom_public" {

  vpc_id                  = aws_vpc.help_me.id
  cidr_block              = "10.80.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "I_can_see_the_light!"
  }
}

resource "aws_subnet" "freedom_public" {

  vpc_id                  = aws_vpc.help_me.id
  cidr_block              = "10.80.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Freedom!"
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

resource "aws_subnet" "The_secured_vault_private" {

  vpc_id            = aws_vpc.help_me.id
  cidr_block        = "10.80.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "The_vault!"
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
  subnet_id     = aws_subnet.sweet_freedom_public.id

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
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.my-ec2-sg.id
  cidr_ipv4         = "0.0.0.0/0"
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

  tags = {
    Name = "my-rds-sg01"
  }
}

resource "aws_security_group_rule" "ec2_to_rds_access" {
  type              = "ingress"
  security_group_id = aws_security_group.my-rds-sg.id
  # cidr_blocks              = [aws_vpc.help_me.cidr_block]
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
  subnet_ids  = [aws_subnet.the_frozen_hell_of_hoath_private.id, aws_subnet.The_secured_vault_private.id]
  description = "this will have the RDS in the private subnet"

  tags = {
    Name = "my-rds-subnet-group"
  }
}


################ RDS Instance: MySQL ###################


resource "aws_db_instance" "my_instance_rds" {
  identifier                      = "lab-mysql"
  engine                          = "mysql"
  instance_class                  = "db.t3.micro"
  allocated_storage               = 20
  db_name                         = var.rds_db_name
  username                        = var.rds_user_name
  password                        = var.rds_db_password
  enabled_cloudwatch_logs_exports = ["error"]

  availability_zone = "us-east-1a"

  db_subnet_group_name   = aws_db_subnet_group.my_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.my-rds-sg.id]

  publicly_accessible = false
  skip_final_snapshot = true


  tags = {
    Name = "my-rds-instance"
  }
}

################## IAM Role & EC2 Instance #####################

resource "aws_iam_role" "my_ec2_role" {
  name = "my-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}


########### IAM POLICY ATTACHMENT ###############################
resource "aws_iam_role_policy_attachment" "my_ec2_secrets_attach" {
  role       = aws_iam_role.my_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "my_ec2_ssm" {
  role       = aws_iam_role.my_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "my_ec2_cloudwatch_agent" {
  role       = aws_iam_role.my_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

############### IAM ROLE POLICY ############################
resource "aws_iam_role_policy" "specific_access_policy" {
  name = "EC2_to_Secrets"
  role = aws_iam_role.my_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.account_ID}:secret:lab3/rds/mysql*"
        ]


      },
    ]
  })
}

resource "aws_iam_role_policy" "specific_access_policy_parameters" {
  name = "EC2_to_Parameters"
  role = aws_iam_role.my_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DescribeParameters"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.account_ID}:parameter/lab/db/*"
        ]


      },
    ]
  })
}

resource "aws_iam_role_policy" "specific_access_cloudwatch_agent" {
  name = "EC2_to_Cloudwatch_agent"
  role = aws_iam_role.my_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups"

        ]
        Effect = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.my_log_group.arn}:*"
        ]


      },
    ]
  })
}

############## PARAMETER STORE ###############
resource "aws_ssm_parameter" "rds_db_endpoint_parameter" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.my_instance_rds.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}


resource "aws_ssm_parameter" "rds_db_port_parameter" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.my_instance_rds.port)

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}


resource "aws_ssm_parameter" "rds_db_name_parameter" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.rds_db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}


############# CLOUDWATCH LOG GROUP ##############
resource "aws_cloudwatch_log_group" "my_log_group" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7

}


############# METRIC ALARM ################################
resource "aws_cloudwatch_metric_alarm" "my_db_alarm" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab3/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.my_created_ec2.id
  }

  alarm_actions = [aws_sns_topic.my_sns_topic.arn]
  ok_actions    = [aws_sns_topic.my_sns_topic.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}



################ SNS TOPIC #########################
resource "aws_sns_topic" "my_sns_topic" {
  name = "${local.name_prefix}-db-incidents"
}

############## EMAIL SUBSCRIPTION ##############################
resource "aws_sns_topic_subscription" "my_sns_sub01" {
  topic_arn = aws_sns_topic.my_sns_topic.arn
  protocol  = "email"
  endpoint  = var.sns_sub_email_endpoint
}

############ INSTANCE PROFILE ###############
resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
  name = "my-instance-profile01"
  role = aws_iam_role.my_ec2_role.name
}

############ EC2 INSTANCE: APP HOST ##################################

resource "aws_instance" "my_created_ec2" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.sweet_freedom_public.id
  vpc_security_group_ids = [aws_security_group.my-ec2-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_agent_profile.name
  availability_zone      = "us-east-1a"

  user_data = data.cloudinit_config.my_config_files.rendered
  tags = {
    Name = "${local.name_prefix}-ec201"
  }
  depends_on = [aws_cloudwatch_log_group.my_log_group]
}



############ SECRETS MANAGER FOR DB CREDENTIALS #####################


resource "aws_secretsmanager_secret" "my_db_secret" {
  name                    = "lab3/rds/mysql"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "my_db_secret_version" {
  secret_id = aws_secretsmanager_secret.my_db_secret.id

  secret_string = jsonencode({
    username = aws_db_instance.my_instance_rds.username
    password = aws_db_instance.my_instance_rds.password
    engine   = "mysql"
    host     = aws_db_instance.my_instance_rds.address
    port     = aws_db_instance.my_instance_rds.port
    dbname   = "lab-mysql"
  })
}
