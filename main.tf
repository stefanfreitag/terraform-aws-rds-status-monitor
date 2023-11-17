# A random identifier used for naming resources
resource "random_id" "id" {
  byte_length = 8
}

# IAM role
resource "aws_iam_role" "rds_health_lambda_role" {
  name               = "rds-health-lambda-role-${random_id.id.hex}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = var.tags
}

# IAM role attachment
resource "aws_iam_role_policy_attachment" "rds_health_permissions" {
  role       = aws_iam_role.rds_health_lambda_role.name
  policy_arn = aws_iam_policy.rds_health_lambda_role_policy.arn

  depends_on = [aws_iam_policy.rds_health_lambda_role_policy,
  aws_iam_role.rds_health_lambda_role]
}

resource "aws_iam_policy" "rds_health_lambda_role_policy" {
  name        = "rds-health-lambda-role-policy-${random_id.id.hex}"
  path        = "/"
  description = "IAM policy rds health solution lambda"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/aws/lambda/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "rds:DescribeDBInstances"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
          "Action": [
               "cloudwatch:PutMetricData"
          ],
          "Resource": "*",
          "Effect": "Allow"
        }
    ]
}
EOF
  tags        = var.tags
}

resource "aws_lambda_function" "rds_health_lambda" {
  filename                       = data.archive_file.status_checker_code.output_path
  function_name                  = "rds_status_monitor-${random_id.id.hex}"
  description                    = "RDS Status Monitor"
  role                           = aws_iam_role.rds_health_lambda_role.arn
  handler                        = "index.lambda_handler"
  runtime                        = "python3.11"
  reserved_concurrent_executions = 1
  memory_size                    = var.memory_size
  source_code_hash               = data.archive_file.status_checker_code.output_base64sha256
  timeout                        = 60
  tags                           = var.tags
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      RDS_ARNS              = join(",", var.rds_arns)
      ENABLE_CLOUDWATCH_METRICS = var.enable_cloudwatch_alarms
      SUPPRESS_STATES           = join(",", var.ignore_states)
    }
  }

}

# eventbridge rule
resource "aws_cloudwatch_event_rule" "rds_health_lambda_schedule" {
  name                = "rds-health-eventbridge-rule-${random_id.id.hex}"
  description         = "Scheduled execution of the RDS monitor"
  schedule_expression = var.schedule_expression
  is_enabled          = true
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "rds_health_lambda_target" {
  arn  = aws_lambda_function.rds_health_lambda.arn
  rule = aws_cloudwatch_event_rule.rds_health_lambda_schedule.name
}

resource "aws_lambda_permission" "allow_cw_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_health_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_health_lambda_schedule.arn
}


# Log group for the Lambda function
resource "aws_cloudwatch_log_group" "rds_health_lambda_log_groups" {
  name              = "/aws/lambda/rds_status_monitor-${random_id.id.hex}"
  retention_in_days = var.log_retion_period_in_days
  tags              = var.tags
}


resource "aws_cloudwatch_metric_alarm" "this" {
  for_each                  = toset(local.rds_names)
  namespace                 = "Custom/RDS"
  period                    = 300
  metric_name               = "Status"
  alarm_name                = "rds-status-monitor-${each.key}-${random_id.id.hex}"
  comparison_operator       = "GreaterThanThreshold"
  alarm_description         = "This alarm triggers on RDS status."
  evaluation_periods        = 2
  statistic                 = "Average"
  threshold                 = 0
  treat_missing_data        = var.cloudwatch_alarms_treat_missing_data
  alarm_actions             = []
  insufficient_data_actions = []
  ok_actions                = []
  dimensions = {
    DBInstanceIdentifier = each.key
  }
  tags = var.tags
}

locals {
  rds_names = var.enable_cloudwatch_alarms ? sort([for arn in var.rds_arns : element(split("/", arn), 1)]) : []
}
