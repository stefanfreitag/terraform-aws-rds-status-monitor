module "rds_monitor" {
  source                   = "../.."
  rds_arns= ["endur-r4endur", "endur-r7endur"]
  enable_cloudwatch_alarms = false
  schedule_expression      = "rate(2 minutes)"
  tags = {
    "Name" = "rds-monitor"
  }
}
