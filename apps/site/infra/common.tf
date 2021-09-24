locals {
  tags = {
    name    = var.instance_name
    created = var.current_date
  }
  s3_origin = "s3_origin"
}