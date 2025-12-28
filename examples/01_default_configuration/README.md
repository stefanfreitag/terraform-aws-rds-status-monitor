## Example 01

Create a MSK status monitor with only a tag attached.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>6.21 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rds_monitor"></a> [rds\_monitor](#module\_rds\_monitor) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_alert_arns"></a> [cloudwatch\_alert\_arns](#output\_cloudwatch\_alert\_arns) | A map consisting of RDS names and their CloudWatch metric alarm ARNs. |
<!-- END_TF_DOCS -->
