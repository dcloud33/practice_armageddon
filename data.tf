data "aws_availability_zones" "available" {
  state = "available"
}

data "cloudinit_config" "my_config_files" {
  gzip          = false
  base64_encode = false

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


data "aws_caller_identity" "aws_caller" {}


# data "aws_route53_zone" "piecourse" {
#   name         = "piecourse.com"
#   private_zone = false
# }

data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}


# Origin-driven cache policy (AWS managed)
data "aws_cloudfront_cache_policy" "use_origin_cache_control" {
  name = "UseOriginCacheControlHeaders"
}

# (Optional) If your endpoint truly varies by query strings:
# data "aws_cloudfront_cache_policy" "use_origin_cache_control_qs" {
#   name = "UseOriginCacheControlHeaders-QueryStrings"
# }
