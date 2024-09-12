# IAM role
resource "aws_iam_role" "this" {
  name               = var.name
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
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn

  depends_on = [aws_iam_policy.this,
  aws_iam_role.this]
}

resource "aws_iam_policy" "this" {
  name        = var.name
  path        = "/"
  description = var.name
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

resource "aws_lambda_function" "this" {
  filename                       = data.archive_file.status_checker_code.output_path
  function_name                  = var.name
  description                    = var.name
  role                           = aws_iam_role.this.arn
  handler                        = "index.lambda_handler"
  runtime                        = "python3.12"
  layers                         = var.lambda_insights_layers_arn == null ? [] : [var.lambda_insights_layers_arn]
  reserved_concurrent_executions = 2
  memory_size                    = var.memory_size
  source_code_hash               = data.archive_file.status_checker_code.output_base64sha256
  timeout                        = var.timeout
  tags                           = var.tags
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      RDS_ARNS                  = join(",", var.rds_arns)
      ENABLE_CLOUDWATCH_METRICS = var.enable_cloudwatch_alarms
      SUPPRESS_STATES           = join(",", var.ignore_states)
    }
  }
}

# eventbridge rule
resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = "Scheduled execution of the RDS monitor"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.name
}

resource "aws_lambda_permission" "allow_cw_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}


# Log group for the Lambda function
resource "aws_cloudwatch_log_group" "rds_health_lambda_log_groups" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retion_period_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each                  = toset(local.rds_names)
  namespace                 = "Custom/RDS"
  period                    = 300
  metric_name               = "Status"
  alarm_name                = "${var.name}-${each.key}"
  comparison_operator       = "GreaterThanThreshold"
  alarm_description         = "This alarm triggers on RDS status."
  evaluation_periods        = 2
  statistic                 = "Average"
  threshold                 = 0
  treat_missing_data        = var.cloudwatch_alarms_treat_missing_data
  alarm_actions             = var.alarm_actions
  insufficient_data_actions = var.insufficient_data_actions
  ok_actions                = var.ok_actions
  dimensions = {
    DBInstanceIdentifier = each.key
  }
  tags = var.tags
}

locals {
  rds_names = var.enable_cloudwatch_alarms ? sort([for arn in var.rds_arns : element(split(":", arn), 6)]) : []
}
