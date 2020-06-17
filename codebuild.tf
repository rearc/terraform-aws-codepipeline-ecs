
data "aws_subnet" "private_subnet_a" {
  id  = var.subnets[0]
}

data "aws_vpc" "codebuild_vpc" {
  id = data.aws_subnet.private_subnet_a.vpc_id
}

data "aws_subnet" "private_subnets" {
  count = length(var.subnets)
  id    = var.subnets[count.index]
}

resource "aws_codebuild_project" "build" {
  count         = contains(var.pipeline_types,"build-unit-deploy") || contains(var.pipeline_types,"build-deploy") || contains(var.pipeline_types,"build-unit") || contains(var.pipeline_types,"build-publish") || contains(var.pipeline_types,"build") || contains(var.pipeline_types,"build-unit-migrate-deploy-update") ? 1 : 0
  
  name          = "${var.app_name}-${local.stack}-build"
  description   = ""
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "e2e_tests" {
  count         = contains(var.pipeline_types,"e2e") ? 1 : 0

  name          = "${var.app_name}-${local.stack}-e2e_tests"
  description   = "environment for running end-to-end tests"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "cypress/browsers:chrome69"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec-cypress.yml"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "unit_tests" {
  count         = contains(var.pipeline_types,"build-unit-deploy") || contains(var.pipeline_types,"build-unit") || contains(var.pipeline_types,"build-unit-migrate-deploy-update") ? 1 : 0

  name          = "${var.app_name}-${local.stack}-unit_tests"
  description   = "environment for running unit tests"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec-rspec.yml"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "publish" {
  count         = contains(var.pipeline_types,"build-publish") ? 1 : 0

  name          = "${var.app_name}-${local.stack}-publish"
  description   = "environment for running publish project"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec-publish.yml"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "db_migrate" {
  count         = contains(var.pipeline_types,"build-unit-migrate-deploy-update") ? 1 : 0

  name          = "${var.app_name}-${local.stack}-db_migrate"
  description   = "environment for triggering db migrate task"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec-db_migrate.yml"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "update_service" {
  count         = contains(var.pipeline_types,"build-unit-migrate-deploy-update") ? 1 : 0

  name          = "${var.app_name}-${local.stack}-update_service"
  description   = "environment for triggering db migrate task"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_iam_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${var.aws_account_id}"
    }

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = "${var.ecr_repo_name}"
    }

    environment_variable {
      name  = "APP_NAME"
      value = "${var.app_name}"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }

    environment_variable {
      name  = "STACK"
      value = "${local.stack}"
    }

    environment_variable {
      name  = "CONTAINER_COMMAND"
      value = "${jsonencode(var.task_command)}"
    }

    environment_variable {
      name  = "CONTAINER_SECRETS"
      value = "${jsonencode(var.task_secrets)}"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec-update_service.yml"
  }

  vpc_config {
    vpc_id = data.aws_vpc.codebuild_vpc.id

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}