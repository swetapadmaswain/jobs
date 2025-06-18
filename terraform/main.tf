terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta3"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "test" {
    bucket = "my-tf-test-bucket-uebbdhdhdhddhdh"

    tags = {
      Name        = "My bucket"
      Environment = "Dev"
    }
  
}