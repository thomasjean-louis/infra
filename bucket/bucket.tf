variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

variable "region" {
  type = string
}

resource "random_string" "random_string" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

resource "aws_s3_bucket" "project-bucket" {
  bucket = "s3-${var.region}-${var.app_name}-${random_string.random_string.result}-${var.deployment_branch}"

  tags = {
    Name = "s3-${var.region}-${var.app_name}-${random_string.random_string.result}-${var.deployment_branch}"
  }
}

output "s3-bucket-name" {
  value = aws_s3_bucket.project-bucket.bucket
}
