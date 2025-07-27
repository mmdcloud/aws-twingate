terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    twingate = {
      source = "twingate/twingate"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "random" {}
