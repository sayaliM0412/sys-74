
provider "aws" {
  profile = "default"
  region = "us-west-2"
}


resource "aws_iam_role" "sys_74" {
  name = "sys-74-role"

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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.sys_74.name
}


resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_sns_topic" "sys_74" {
  name = "sys_74-topic"
}

resource "aws_codedeploy_app" "sys_74" {
  compute_platform = "ECS"
  name             = "sys-74_codedeploy_app"
  # service_role_arn       = aws_iam_role.sys_74.name
}

resource "aws_codedeploy_deployment_group" "sys_74" {
  app_name              = aws_codedeploy_app.sys_74.name
  deployment_group_name = "sys_74-group"
  service_role_arn      = aws_iam_role.sys_74.arn

trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "sys_74-trigger"
    trigger_target_arn = aws_sns_topic.sys_74.arn
  }

load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.sys_74.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}