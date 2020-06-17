locals {
  bucket_names = var.bucket_name != "" ? [ var.codepipeline_bucket_name, var.bucket_name ] : [  var.codepipeline_bucket_name ]
  stack        = var.stack != "" ? var.stack : var.environment
}

data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.codepipeline_bucket_name
}

data "aws_s3_bucket" "buckets" {
  count = length(local.bucket_names)

  bucket= local.bucket_names[count.index]
}

resource "aws_codepipeline" "b_pipeline" {
  count    = contains(var.pipeline_types,"build") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build"
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
        ProjectName          = aws_codebuild_project.build[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }
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
        ProjectName          = aws_codebuild_project.build[0].name
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
        ApplicationName                = aws_codedeploy_app.codedeploy[0].name
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
        ProjectName          = aws_codebuild_project.build[0].name
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
        ProjectName          = "${aws_codebuild_project.unit_tests[0].name}"
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

}

resource "aws_codepipeline" "bp_pipeline" {
  count    = contains(var.pipeline_types,"build-publish") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build-publish"
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
        ProjectName          = aws_codebuild_project.build[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "Publish"

    action {
      name             = "Publish"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.publish[0].name
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
        ProjectName          = aws_codebuild_project.build[0].name
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
        ProjectName          = aws_codebuild_project.unit_tests[0].name
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
        ApplicationName                = aws_codedeploy_app.codedeploy[0].name
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

resource "aws_codepipeline" "bumdu_pipeline" {
  count    = contains(var.pipeline_types,"build-unit-migrate-deploy-update") ? 1 : 0
  name     = "${var.app_name}-${local.stack}-build-unit-migrate-deploy-update"
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
        ProjectName          = aws_codebuild_project.build[0].name
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
        ProjectName          = aws_codebuild_project.unit_tests[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }

  stage {
    name = "DBMigrate"

    action {
      name             = "DBMigrate"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["MigrateArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.db_migrate[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"},
                                           {name: "SKIP_MIGRATE", type: "PLAINTEXT", value: "no"}])
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
        ApplicationName                = aws_codedeploy_app.codedeploy[0].name
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

  stage {
    name = "UpdateService"

    action {
      name             = "UpdateService"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["UpdateArtifact"]
      version          = "1"

      configuration    = {
        ProjectName          = aws_codebuild_project.update_service[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
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
        ProjectName          = aws_codebuild_project.e2e_tests[0].name
        EnvironmentVariables = jsonencode([{name: "COMMIT_ID", type: "PLAINTEXT", value: "${var.commit_id}"}])
      }
    }
  }
}
