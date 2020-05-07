<a href="https://www.rearc.io/data/">
    <img src="https://www.rearc.io/wp-content/uploads/2018/11/Logo.png" alt="Rearc Logo" title="Rearc Logo" height="52" />
</a>

# terraform-aws-codepipeline-ecs

Terraform module to provide CI/CD through CodePipeline, CodeBuild, and CodeDeploy to build, test, and deploy applications developed on GitHub to ECS.

## Introduction

The module will create:

* CodePipeline pipelines (build -> unit tests -> deploy -> end-to-end tests and variations)
* CodeBuild projects (build, unit tests, deploy, and end-to-end tests)
* CodeDeploy application and deployment group
* Required IAM roles
* GitHub webhooks

## Usage

By default, this will build the application and run unit tests on commit to the master branch.
```hcl
module "pipeline_ecs" {
  source                   = "git::https://github.com/rearc/terraform-aws-codepipeline-ecs.git"
  aws_account_id           = "123456789012"
  region                   = "us-east-1"
  github_token             = "xxxxxxxxxxxxxx"
  repo_owner               = "rearc"
  app_name                 = "rails-sample-app"
}
```
