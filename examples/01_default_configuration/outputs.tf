output "cloudwatch_alert_arns" {
  description = "A map consisting of RDS names and their CloudWatch metric alarm ARNs."
  value       = module.rds_monitor.cloudwatch_metric_alarm_arns
}
