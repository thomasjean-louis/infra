variable "app_name" {
  type = string
}

variable "region" {
  type = string
}

variable "author" {
  type = string
}

resource "aws_s3_bucket" "project-bucket" {
  bucket = "s3-${var.region}-${var.app_name}-${var.author}"

  tags = {
    Name = "s3-${var.region}-${var.app_name}-${var.author}"
  }
}
