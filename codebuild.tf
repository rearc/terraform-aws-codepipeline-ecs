
# Need to refactor to handle subnet_ids inputs other than a list of two subnet IDs.
locals {
    private_subnet_a_id = var.subnets[0]
    private_subnet_b_id = var.subnets[1]
}

data "aws_subnet" "private_subnet_a" {
  id  = "${local.private_subnet_a_id}"
}

data "aws_subnet" "private_subnet_b" {
  id  = "${local.private_subnet_b_id}"
}

resource "aws_codebuild_project" "build" {
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
    vpc_id = "${data.aws_subnet.private_subnet_a.vpc_id}"

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "e2e_tests" {
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
    buildspec       = "test_buildspec.yml"
  }

  vpc_config {
    vpc_id = "${data.aws_subnet.private_subnet_a.vpc_id}"

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}

resource "aws_codebuild_project" "unit_tests" {
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
    buildspec       = "unittest_buildspec.yml"
  }

  vpc_config {
    vpc_id = "${data.aws_subnet.private_subnet_a.vpc_id}"

    subnets = var.subnets

    security_group_ids = var.security_group_ids
  }
}