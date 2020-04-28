provider "aws" {
  region  = "us-east-1"
}

module "pipeline_ecs" {
  source                   = "../.."
  aws_account_id           = "123456789012"
  region                   = "us-east-1"
  github_token             = "xxxxxxxxxxxxxx"
  repo_owner               = "rearc"
  app_name                 = "rails-sample-app"
}