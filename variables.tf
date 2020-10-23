variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "region" {
  type        = string
  description = "AWS Region, e.g. us-east-1"
}

variable "github_token" {
  type        = string
  description = "GitHub OAuth token"
}

variable "repo_owner" {
  type        = string
  description = "GitHub Organization or Username"
}

variable "app_name" {
  type        = string
  description = "GitHub repository name of the application to be built and deployed to ECS"
}

variable "pipeline_types" {
  type        = list(string)
  description = "e.g. build, build-deploy, build-unit-deploy, e2e"
  default     = ["build-deploy"]
}

variable "ecr_repo_name" {
  type        = string
  description = "Elastic Container Registry repository name to store the Docker images built by this module"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Infrastructure environment, e.g. staging or production"
  default     = ""
}

variable "stack" {
  type        = string
  description = "Name to differentiate applications deployed in the same infrastructure environment"
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket for CodeBuild to have read/write access to"
  default     = ""
}

variable "codepipeline_bucket_name" {
  type        = string
  description = "S3 bucket to store CodePipeline artifacts"
  default     = ""
}

variable "branch_name" {
  type        = string
  description = "Branch of the GitHub repository, e.g. master"
  default     = "master"
}

variable "commit_id" {
  type        = string
  description = "Shorthand version of the commit ID, e.g. 42e2e5a"
  default     = "HEAD"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Elastic Container Service cluster name to deploy services to"
  default     = ""
}


variable "subnets" {
  type        = list(string)
  description = "VPC subnets to run CodeBuild projects in"
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "VPC security groups to run CodeBuild projects in"
  default     = []
}

variable "listener_arns" {
  type        = list(string)
  description = "ARNs of the load balancer listeners for the prod_traffic_route"
  default     = []
}

variable "blue_target_group_arn" {
  type        = string
  description = "Blue target group ARN for the service"
  default     = ""
}

variable "green_target_group_arn" {
  type        = string
  description = "Green target group ARN for the service"
  default     = ""
}

variable "task_command" {
  type = list(string)
  description = "Command injected into the ECS task definition file"
  default = []
}

variable "task_secrets" {
  type = list(object({
    name = string
    valueFrom = string
  }))
  description = "Secrets injected into the ECS task definition file"
  default = []
}

variable "task_environment" {
  type = list(object({
    name = string
    value = string
  }))
  description = "Environment variables injected into the ECS task definition file"
  default = []
}

variable "task_role_arn" {
  type        = string
  description = "IAM role for task to run as"
  default     = ""
}

variable "build_image" {
  type        = string
  default     = "aws/codebuild/standard:3.0"
  description = "Docker image for build stages"
}

variable "e2e_image" {
  type        = string
  default     = "cypress/browsers:chrome69"
  description = "Docker image for e2e stages"
}

variable "repo_path" {
  type        = string
  default     = "."
  description = "Path in repository to look for Dockerfile and buildspecs"
}