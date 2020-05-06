resource "aws_iam_role" "codebuild_iam_role" {
  name               = "${var.app_name}_${local.stack}_codebuild_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role   = "${aws_iam_role.codebuild_iam_role.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/${var.environment}/*"
    },
    {
        "Action": [
            "s3:*"
        ],
        "Resource": "${data.aws_s3_bucket.codepipeline_bucket.arn}/*",
        "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:${var.region}:${var.aws_account_id}:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": data.aws_subnet.private_subnets.*.arn,
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
  {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
    
EOF
}

resource "aws_iam_role" "codedeploy_iam_role" {
  name = "${var.app_name}_${local.stack}_deploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.codedeploy_iam_role.name}"
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole2" {
  policy_arn = "${aws_iam_policy.codedeploy_ecs_policy.arn}"
  role       = "${aws_iam_role.codedeploy_iam_role.name}"

}


resource "aws_iam_policy" "codedeploy_ecs_policy" {
  name        = "${var.app_name}_${local.stack}_codedeploy_ecs_policy"
  path        = "/"
  description = "codedeploy_ecs_policy"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
            ]
      },
        {
            "Action": [
                "ecs:*",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:ModifyRule",
                "lambda:InvokeFunction",
                "cloudwatch:DescribeAlarms",
                "sns:Publish",
                "s3:GetObject",
                "s3:GetObjectMetadata",
                "s3:GetObjectVersion",
                "ecr:*",
                "codedeploy:CreateApplication",
                "codedeploy:CreateDeployment",
                "codedeploy:CreateDeploymentGroup",
                "codedeploy:GetApplication",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentGroup",
                "codedeploy:ListApplications",
                "codedeploy:ListDeploymentGroups",
                "codedeploy:ListDeployments",
                "codedeploy:StopDeployment",
                "codedeploy:GetDeploymentTarget",
                "codedeploy:ListDeploymentTargets",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:GetApplicationRevision",
                "codedeploy:RegisterApplicationRevision",
                "codedeploy:BatchGetApplicationRevisions",
                "codedeploy:BatchGetDeploymentGroups",
                "codedeploy:BatchGetDeployments",
                "codedeploy:BatchGetApplications",
                "codedeploy:ListApplicationRevisions",
                "codedeploy:ListDeploymentConfigs",
                "codedeploy:ContinueDeployment",
                "sns:ListTopics",
                "cloudwatch:DescribeAlarms",
                "lambda:ListFunctions"
                    ],
                    "Resource": "*",
                    "Effect": "Allow"
                }
    ]
}
EOF

}


resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-${local.stack}_pipeline_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.app_name}-${local.stack}-pipeline-role"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Statement": [
    {
        "Action": [
            "iam:PassRole"
        ],
        "Resource": "*",
        "Effect": "Allow",
        "Condition": {
            "StringEqualsIfExists": {
                "iam:AWSServiceName": [
                    "cloudformation.amazonaws.com",
                    "elasticbeanstalk.amazonaws.com",
                    "ec2.amazonaws.com",
                    "ecs-tasks.amazonaws.com"
                ]
            }
        }
    },
    {
        "Action": [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplication",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": [
            "elasticbeanstalk:*",
            "ec2:*",
            "elasticloadbalancing:*",
            "autoscaling:*",
            "cloudwatch:*",
            "s3:*",
            "sns:*",
            "rds:*",
            "sqs:*",
            "ecs:*",
            "codebuild:*"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },

    {
        "Effect": "Allow",
        "Action": [
            "servicecatalog:ListProvisioningArtifacts",
            "servicecatalog:CreateProvisioningArtifact",
            "servicecatalog:DescribeProvisioningArtifact",
            "servicecatalog:DeleteProvisioningArtifact",
            "servicecatalog:UpdateProduct"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:DescribeImages",
            "ecr:Get"
        ],
        "Resource": "*"
    }
],
"Version": "2012-10-17"
}

EOF
}
