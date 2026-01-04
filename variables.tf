variable "aws_region" {
  description = "AWS Region that I'd used because...I'm forgetful"
  default     = "us-east-1"
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-068c0051b15cdb81" 
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t2.micro"
}




variable "rds_db_name" {
    type = string
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
    type = string
    default = "my_unique_name"
}



