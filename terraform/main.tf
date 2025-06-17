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
    bucket = "mytestbucker_uebbdhdhdhddhdh-87979"

    tags = {
        Name = "My_buckey"
        Environment = "Dev"
    }
  
}