resource "aws_codedeploy_app" "codedeploy" {
  count            = contains(var.pipeline_types,"build-unit-deploy") || contains(var.pipeline_types,"build-deploy") ? 1 : 0
  
  name             = "${var.app_name}_${local.stack}_codedeploy_app"
  compute_platform = "ECS"
}


resource "aws_codedeploy_deployment_group" "deployment_group" {
  count                  = contains(var.pipeline_types,"build-unit-deploy") || contains(var.pipeline_types,"build-deploy") || contains(var.pipeline_types,"deploy")  ? 1 : 0
  app_name               = aws_codedeploy_app.codedeploy[0].name
  deployment_group_name  = "${var.app_name}_${local.stack}_deployment_group"
  service_role_arn       = "${aws_iam_role.codedeploy_iam_role.arn}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = "${var.ecs_cluster_name}"
    service_name = "${local.stack}_${var.app_name}"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  dynamic "blue_green_deployment_config" {
    for_each = var.blue_target_group_arn == "" ? [] : [1]
    
    content {
      deployment_ready_option {
        action_on_timeout = "CONTINUE_DEPLOYMENT"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = 5
      }
    }
  }

  dynamic "deployment_style" {
    for_each = var.blue_target_group_arn == "" ? [] : [1]

    content {
      deployment_option = "WITH_TRAFFIC_CONTROL"
      deployment_type   = "BLUE_GREEN"
    }
  }

  dynamic "load_balancer_info" {
    for_each = var.blue_target_group_arn == "" ? [] : [1]

    content {
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
}