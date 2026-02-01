############################################
# Lab 2B-Honors - Origin Driven Caching (Managed Policies)
############################################

# Explanation: Chewbacca uses AWS-managed policies—battle-tested configs so students learn the real names.
data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers01" {
  name = "UseOriginCacheControlHeaders"
}

# Explanation: Same idea, but includes query strings in the cache key when your API truly varies by them.
data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers_qs01" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# Explanation: Origin request policies let us forward needed stuff without polluting the cache key.
# (Origin request policies are separate from cache policies.) :contentReference[oaicite:6]{index=6}
data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer01" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer_except_host01" {
  name = "Managed-AllViewerExceptHostHeader"
}

############################################
# Lab 2B-Honors - Origin Driven Caching (Managed Policies)
#
# Purpose:
#   - /api/public-feed : CloudFront honors origin Cache-Control (public, s-maxage=30)
#   - /api/*           : safe default (no caching)
#   - /static/*        : keep your baseline aggressive caching behavior (unchanged)
#
# Notes:
#   - AWS managed cache policy names are *usually* prefixed with "Managed-",
#     but these two are exceptions:
#       - UseOriginCacheControlHeaders
#       - UseOriginCacheControlHeaders-QueryStrings
############################################

############################
# 1) AWS-managed policies via data sources
############################

# A) Origin-driven caching (honor origin Cache-Control; default to NOT caching when Cache-Control absent)
data "aws_cloudfront_cache_policy" "use_origin_cache_control_headers" {
  name = "UseOriginCacheControlHeaders"
}

# Optional variant: includes query strings in the cache key (ONLY use if your origin truly varies by them)
data "aws_cloudfront_cache_policy" "use_origin_cache_control_headers_qs" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# B) Safe default for APIs: caching disabled
data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Origin request policy: forward only what the origin truly needs (separate from cache key).
# If your baseline already uses a narrower policy (recommended), keep it.
data "aws_cloudfront_origin_request_policy" "managed_all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

############################
# 2) Honors overlay: patch CloudFront behaviors
############################
# Add/merge these blocks into your existing aws_cloudfront_distribution resource.
#
# IMPORTANT: Keep the cache key minimal.
#   - For /api/public-feed, prefer *not* varying by headers/cookies/querystrings unless truly necessary,
#     otherwise you'll fragment the cache and tank hit ratio.

# Example merge target:
# resource "aws_cloudfront_distribution" "this" {
#   ...
#   # (A) Origin-driven caching for /api/public-feed
#   ordered_cache_behavior { ... }
#
#   # (B) Safe default for /api/*
#   ordered_cache_behavior { ... }
#   ...
# }
#
# Replace aws_cloudfront_distribution.this and your origin_id to match your baseline module.

# (A) /api/public-feed -> origin-driven caching (honor Cache-Control: public, s-maxage=30)
# If you do NOT need query strings in the cache key, use use_origin_cache_control_headers.
# If you DO need query strings, switch cache_policy_id to use_origin_cache_control_headers_qs.
#
# IMPORTANT:
#   - Viewer max-age should be 0 at origin (max-age=0) so browsers don't cache;
#     shared CDN uses s-maxage=30.
#   - CloudFront will cache for 30 seconds when s-maxage=30 is present.
#
# ordered_cache_behavior {
#   path_pattern           = "/api/public-feed"
#   target_origin_id       = local.app_origin_id
#   viewer_protocol_policy = "redirect-to-https"
#
#   allowed_methods = ["GET", "HEAD", "OPTIONS"]
#   cached_methods  = ["GET", "HEAD"]
#
#   compress = true
#
#   cache_policy_id          = data.aws_cloudfront_cache_policy.use_origin_cache_control_headers.id
#   origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer_except_host.id
# }

# (B) /api/* -> safe default (no caching)
# ordered_cache_behavior {
#   path_pattern           = "/api/*"
#   target_origin_id       = local.app_origin_id
#   viewer_protocol_policy = "redirect-to-https"
#
#   allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#   cached_methods  = ["GET", "HEAD"]
#
#   compress = true
#
#   cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
#   origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer_except_host.id
# }
