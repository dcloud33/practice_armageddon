data "aws_availability_zones" "available" {
  state = "available"
}

data "cloudinit_config" "my_config_files" {
  gzip          = true
  base64_encode = true

  # First script
  part {
    content_type = "text/x-shellscript"
    content      = file("user_data/user_data.sh")
    filename     = "user_data.sh"
  }

  # Second script
  part {
    content_type = "text/x-shellscript"
    content      = file("user_data/cloudwatch_agent_config.sh")
    filename     = "cloudwatch_agent_config.sh"
  }
}
