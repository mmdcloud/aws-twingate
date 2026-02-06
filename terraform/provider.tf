terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    twingate = {
      source  = "twingate/twingate"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "random" {}

provider "twingate" {
  api_token = "WjVvLdiaXY6RH7wI__WSYW4PNsCAPOZRIvKDQG4NvwNdFZTydpPDI3UAry85T31UMmHklSKRJIWVHgaSGxbwMlhUVMhME37blOhCEno6qolv9zuqfPAUbPN_bEKsTKggW5YV6Q"
  network   = var.tg_network
}