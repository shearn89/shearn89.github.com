terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    encrypt = true
    bucket = "shearn89-tfstate"
    dynamodb_table = "terraform-lock-table"
    key    = "shearn89-blog/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}
