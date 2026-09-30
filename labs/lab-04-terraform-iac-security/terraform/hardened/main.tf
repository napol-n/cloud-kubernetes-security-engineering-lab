terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_kms_key" "lab_data" {
  description             = "KMS key for Cloud Kubernetes Security Lab S3 data"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "lab_data" {
  bucket = "cloud-k8s-security-lab-data-example"
}

resource "aws_s3_bucket_public_access_block" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.lab_data.arn
    }
  }
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "cloud-k8s-security-lab-access-logs-example"
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "lab_data" {
  bucket = aws_s3_bucket.lab_data.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
}
