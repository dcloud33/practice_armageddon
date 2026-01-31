############################################
# Lab 2B-Honors+ - Optional invalidation action (run on demand)
############################################

# Explanation: This is Chewbacca’s “break glass” lever — use it sparingly or the bill will bite.
# resource "aws_cloudfront_invalidation" "chewbacca_invalidate_index01" {
#   distribution_id = aws_cloudfront_distribution.my_cf.id

#   # Smallest possible invalidation
#   paths = [
#     "/static/index.html"
#   ]
# }


