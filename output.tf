output "chewbacca_route53_zone_id" {
  value = local.my_zone_id
}

output "piecourse_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "chewbacca_apex_url_https" {
  value = "https://${var.domain_name}"
}

output "chewbacca_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.piecourse_alb_logs_bucket[0].bucket : null
}

output "chewbacca_waf_log_destination" {
  value = var.waf_log_destination
}

output "chewbacca_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.my_waf_logs_bucket[0].bucket : null
}





