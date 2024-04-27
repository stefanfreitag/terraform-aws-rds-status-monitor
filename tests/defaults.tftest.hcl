###
# The schedule expression for the default eventbridge rule should be rate(5 minutes).
###
run "eventbridge_default_schedule_expression" {
  command = plan

  assert {
    condition     = aws_cloudwatch_event_rule.rds_health_lambda_schedule.schedule_expression == "rate(5 minutes)"
    error_message = "Schedule expression is not matching expected default value of rate(5 minutes)."
  }
}

run "eventbridge_default_is_enabled" {
  command = plan

  assert {
    condition     = aws_cloudwatch_event_rule.rds_health_lambda_schedule.state == "ENABLED"
    error_message = "CloudWatch EventBride rule state is not matching state of ENABLED"
  }
}
##
# The default value for CloudWatch Alarm property treat_missing_data should be set to breaching.
##
run "aws_cloudwatch_metric_alarm_default_treat_missing_data" {
  command = plan
  variables {
    rds_arns                         = ["arn:aws:rds:eu-central-1:012345678901:db:my-rds-instance"]
    enable_cloudwatch_alarms             = true
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this["my-rds-instance"].treat_missing_data == "breaching"
    error_message = "The default value for treat_missing_data is not set to breaching."
  }
}
