terraform {

  backend "s3" {
    bucket         = "tf-state-bucket-ardhendu"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }

}

provider "aws" {
  region = "us-east-1"
}