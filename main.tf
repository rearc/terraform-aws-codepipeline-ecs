locals {
  codepipeline_bucket_name = var.codepipeline_bucket_name != "" ? var.codepipeline_bucket_name : "codepipeline-${var.region}-${var.aws_account_id}"
  stack                    = var.stack != "" ? var.stack : var.environment
}

data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = local.codepipeline_bucket_name
}

resource "aws_codepipeline" "bd_pipeline" {
  count    = contains(var.pipeline_types,"build-deploy") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build-deploy"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = data.aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github_source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration    = {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.repo_owner}"
        Repo                 = "${var.app_name}"
        Branch               = "${var.branch_name}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["ImageArtifact", "DefinitionArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["ImageArtifact", "DefinitionArtifact"]
      version         = "1"
      configuration   = {
        ApplicationName                = "${aws_codedeploy_app.codedeploy.name}"
        DeploymentGroupName            = aws_codedeploy_deployment_group.deployment_group[0].deployment_group_name
        TaskDefinitionTemplateArtifact = "DefinitionArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json",
        AppSpecTemplateArtifact        = "DefinitionArtifact"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "ImageArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

resource "aws_codepipeline" "bu_pipeline" {
  count    = contains(var.pipeline_types,"build-unit") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build-unit"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = data.aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github_source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration    = {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.repo_owner}"
        Repo                 = "${var.app_name}"
        Branch               = "${var.branch_name}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["ImageArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["ResultsArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = "${aws_codebuild_project.unit_tests.name}"
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

}

resource "aws_codepipeline" "bud_pipeline" {
  count    = contains(var.pipeline_types,"build-unit-deploy") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build-unit-deploy"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = data.aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github_source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration    = {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.repo_owner}"
        Repo                 = "${var.app_name}"
        Branch               = "${var.branch_name}"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["ImageArtifact", "DefinitionArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["ResultsArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = "${aws_codebuild_project.unit_tests.name}"
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["ImageArtifact", "DefinitionArtifact"]
      version         = "1"
      configuration   = {
        ApplicationName                = "${aws_codedeploy_app.codedeploy.name}"
        DeploymentGroupName            = aws_codedeploy_deployment_group.deployment_group[0].deployment_group_name
        TaskDefinitionTemplateArtifact = "DefinitionArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json",
        AppSpecTemplateArtifact        = "DefinitionArtifact"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "ImageArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }

}

resource "aws_codepipeline" "e_pipeline" {
  count    = contains(var.pipeline_types,"e2e") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-e2e"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = data.aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "github_source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration    = {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.repo_owner}"
        Repo                 = "${var.app_name}"
        Branch               = "${var.branch_name}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Cypress"
    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      version          = "1"

      configuration    = {
        ProjectName          = "${aws_codebuild_project.e2e_tests.name}"
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }
}
