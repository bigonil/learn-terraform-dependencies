provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example_a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}

resource "aws_instance" "example_b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  domain   = "vpc"
  instance = aws_instance.example_a.id
}

resource "aws_s3_bucket" "lb-example" { 
    bucket = "lb-terraform${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  upper   = false  # Only lowercase letters
  special = false  # No special characters
}

resource "aws_s3_bucket_policy" "mycompliantpolicy" {
  bucket = aws_s3_bucket.lb-example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "mycompliantpolicy"
    Statement = [
      {
        Sid       = "HTTPSOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.lb-example.arn,
          "${aws_s3_bucket.lb-example.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "example-public-access-block" {
  bucket = aws_s3_bucket.lb-example.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_instance" "example_c" {
  ami           = data.aws_ami.amazon_linux.id
  associate_public_ip_address = false
  instance_type = "t2.micro"

  depends_on = [aws_s3_bucket.lb-example]
}

module "example_sqs_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = ">= 3.3.0"

  depends_on = [aws_s3_bucket.lb-example, aws_instance.example_c]
}