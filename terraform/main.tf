terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 バックエンドを使う場合（本番環境推奨）:
  # backend "s3" {
  #   bucket         = "your-tf-state-bucket"
  #   key            = "aurora-express-drizzle-sample/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "your-tf-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(
    {
      Project   = var.function_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}
