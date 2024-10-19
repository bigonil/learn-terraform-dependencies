# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  cloud {
    organization = "lb-learn-terraform-prd"
    workspaces {
      name = "learn-terraform-dependencies"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.71.0"
    }
  }

  required_version = "~> 1.2"
}
