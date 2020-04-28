resource "aws_codedeploy_app" "codedeploy" {
  name             = "${var.app_name}_${local.stack}_codedeploy_app"
  compute_platform = "ECS"
}


resource "aws_codedeploy_deployment_group" "deployment_group" {
  count                  = contains(var.pipeline_types,"build-unit-deploy") || contains(var.pipeline_types,"build-deploy") ? 1 : 0
  app_name               = "${aws_codedeploy_app.codedeploy.name}"
  deployment_group_name  = "${var.app_name}_${local.stack}_deployment_group"
  service_role_arn       = "${aws_iam_role.codedeploy_iam_role.arn}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${var.ecs_cluster_name}"
    service_name = "app_${var.app_name}_${local.stack}_service"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = var.listener_arns
      }

      target_group {
        name = "${var.blue_target_group_arn}"
      }

      target_group {
        name = "${var.green_target_group_arn}"
      }
    }
  }
}