module "rds_monitor" {
  source                   = "../.."
  rds_arns                 = ["arn:aws:rds:eu-central-1:565597938316:db:endur-s1endur"]
  enable_cloudwatch_alarms = false
  schedule_expression      = "rate(2 minutes)"
  tags = {
    "Name" = "rds-monitor"
  }
}
