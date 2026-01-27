
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
  subnet_id              = aws_subnet.the_frozen_hell_of_hoath_private.id
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



################## VPC ENDPOINTS #########################

resource "aws_vpc_endpoint" "Secrets_Manager" {
  vpc_id             = aws_vpc.help_me.id
  service_name       = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.the_frozen_hell_of_hoath_private.id]
  security_group_ids = [aws_security_group.my-vpc_endpoint-sg.id]

  tags = {
    Environment = "test"
  }
}

resource "aws_vpc_endpoint" "Logs_vpc_endpoint" {
  vpc_id             = aws_vpc.help_me.id
  service_name       = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.the_frozen_hell_of_hoath_private.id]
  security_group_ids = [aws_security_group.my-vpc_endpoint-sg.id]

  tags = {
    Environment = "test"
  }
}

resource "aws_vpc_endpoint" "ssm_vpc_endpoint" {
  vpc_id             = aws_vpc.help_me.id
  service_name       = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.the_frozen_hell_of_hoath_private.id]
  security_group_ids = [aws_security_group.my-vpc_endpoint-sg.id]

  tags = {
    Environment = "test"
  }
}

resource "aws_vpc_endpoint" "ec2_messages_vpc_endpoint" {
  vpc_id             = aws_vpc.help_me.id
  service_name       = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.the_frozen_hell_of_hoath_private.id]
  security_group_ids = [aws_security_group.my-vpc_endpoint-sg.id]

  tags = {
    Environment = "test"
  }
}


resource "aws_vpc_endpoint" "monitoring_vpc_endpoint" {
  vpc_id             = aws_vpc.help_me.id
  service_name       = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.the_frozen_hell_of_hoath_private.id]
  security_group_ids = [aws_security_group.my-vpc_endpoint-sg.id]

  tags = {
    Environment = "test"
  }
}




########## VPC ENDPOINT SG
resource "aws_security_group" "my-vpc_endpoint-sg" {
  name        = "my-vpc_endpoint-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.help_me.id

  tags = {
    Name = "my-rds-sg01"
  }
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.my-vpc_endpoint-sg.id
  cidr_blocks       = [aws_vpc.help_me.cidr_block]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443

}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_egress" {
  security_group_id = aws_security_group.my-vpc_endpoint-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################ APPLICATION LOAD BALANCER ####################

resource "aws_lb" "test" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my-alb-sg.id]
  subnets            = [aws_subnet.sweet_freedom_public.id, aws_subnet.freedom_public.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}


########### APPLICATION LOAD BALANCER SG

resource "aws_security_group" "my-alb-sg" {
  name        = "my-alb-sg"
  description = "application loadbalancer security group"
  vpc_id      = aws_vpc.help_me.id

  tags = {
    Name = "my-rds-sg01"
  }
}


resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.piecourse_acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

 default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.help_me.id

health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "alb-tg"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.my_created_ec2.id
  port             = 80

  
}

################# ACM

resource "aws_acm_certificate" "piecourse_acm_cert" {
  domain_name       = "piecourse.com"
  validation_method = "DNS"


  tags = {
    Name = "piecourse-acm-cert"
  }
}


resource "aws_acm_certificate_validation" "piecourse_acm_cert" {
  certificate_arn = aws_acm_certificate.piecourse_acm_cert.arn

}



############ ALB SG
resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.my-alb-sg.id
  cidr_blocks       = [aws_vpc.help_me.cidr_block]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443

}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.my-alb-sg.id
  cidr_blocks       = [aws_vpc.help_me.cidr_block]
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80

}


resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.my-alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################# WAF ##########################

resource "aws_wafv2_web_acl" "my_waf" {
 count = var.enable_waf ? 1 : 0

  name  = "alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-waf"
    sampled_requests_enabled   = true
  }

  # Explanation: AWS managed rules are like hiring Rebel commandos — they’ve seen every trick.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "alb-waf-common"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "alb-waf"
  }
}

# Explanation: Attach the shield generator to the customs checkpoint — ALB is now protected.
resource "aws_wafv2_web_acl_association" "waf_assoc" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.test.arn
  web_acl_arn  = aws_wafv2_web_acl.my_waf[0].arn
}

resource "aws_cloudwatch_metric_alarm" "chewbacca_alb_5xx_alarm01" {
  alarm_name          = "lab-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.test.arn
  }

  alarm_actions = [aws_sns_topic.my_sns_topic.arn]

  tags = {
    Name = "lab-alb-5xx-alarm01"
  }
}

################### CLOUDWATCH DASHBOARD ########################

resource "aws_cloudwatch_dashboard" "my_cloudwatch_dashboard01" {
  dashboard_name = "lab-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.test.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "My_unique_name ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.test.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "My ALB: Target Response Time"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["Lab/RDSApp", "DBConnectionErrors", "InstanceId", aws_instance.my_created_ec2.id]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "My App: DB Connection Errors"
        }
      }
    ]
  })
}
