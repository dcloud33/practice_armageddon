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

variable "alb_5xx_threshold" {
  type    = number
  default = 12
}

variable "alb_5xx_evaluation_periods" {
  type    = number
  default = 1
}

variable "alb_5xx_period_seconds" {
  type    = number
  default = 300
}

variable "domain_name" {
  type    = string
  default = "piecourse.com"
}

variable "app_subdomain" {
  type    = string
  default = "app"
}

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  default     = ""
}


variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  type    = string
  default = "lab-alb-logs"
}

variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "s3"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}



variable "cloudfront_acm_cert_arn" {
  type = string
}


variable "waf_scope" {
  type    = string
  default = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.waf_scope)
    error_message = "Please use one of the following values: REGIONAL, CLOUDFRONT"
  }
}

variable "waf_arn" {
  type    = string
  default = null
}

variable "break_glass_invalidate" {
  type    = bool
  default = false
}