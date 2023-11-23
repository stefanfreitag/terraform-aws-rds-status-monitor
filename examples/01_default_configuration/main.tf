module "rds_monitor" {
  source                   = "../.."
  rds_arns                 = []
  enable_cloudwatch_alarms = false
  schedule_expression      = "rate(2 minutes)"
  tags = {
    "Name" = "rds-monitor"
  }
}
