output "role_arn" {
  description = "The ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "cloudwatch_metric_alarm_arns" {
  description = "A map consisting of RDS instance names and their CloudWatch metric alarm ARNs."
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}
