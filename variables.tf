variable "aws_region" {
  description = "AWS Region that I'd used because...I'm forgetful"
  default     = "us-east-1"
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-07ff62358b87c7116"
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t2.micro"
}


variable "rds_db_name" {
  type    = string
  default = "lab"
}




variable "rds_user_name" {
  type    = string
  default = "admin"
}

variable "rds_db_password" {
  type      = string
  sensitive = true
  default   = "mynewpassword1234!!"
}

variable "user_name" {
  type    = string
  default = "my_unique_name"
}

variable "account_ID" {
  type    = string
  default = 724772093504
}

variable "sns_sub_email_endpoint" {
  type    = string
  default = "wheeling2346@gmail.com"
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "alb_5xx_threshold"{
  type = number
  default = 12
}

variable "alb_5xx_evaluation_periods" {
  type = number
  default = 1
}

variable "alb_5xx_period_seconds" {
  type = number
  default = 300
}

