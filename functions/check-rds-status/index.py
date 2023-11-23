from typing import List

import boto3
import os

RDS_ARNS: list[str] = os.environ["RDS_ARNS"].split(",")
ENABLE_CLOUDWATCH_METRICS: str = os.environ["ENABLE_CLOUDWATCH_METRICS"]


def get_valid_states() -> List[str]:
    """
    Returns a list of valid states for RDS instances.
    :return: List of valid states
    """
    try:
        suppress_states: list[str] = os.environ["SUPPRESS_STATES"].split(",")
        additional_states = list(map(lambda x: x.lower(), suppress_states))
        return ["available"] + additional_states
    except Exception as e:
        print("Error parsing environment variable SUPPRESS_STATES: {}".format(e))
        return ["available"]


def lambda_handler(event, context):
    region = "eu-central-1"

    # Create boto clients
    rds = boto3.client("rds", region_name=region)
    cloudwatch = boto3.client("cloudwatch")

    valid_states = get_valid_states()
    print(
        "Notifications suppressed for these RDS states: {}".format(
            ", ".join(valid_states)
        )
    )

    for arn in RDS_ARNS:
        try:
            response = rds.describe_db_instances(DBInstanceIdentifier=arn)
        except Exception as e:
            print(
                f"An error occurred when trying to describe the RDS instance {arn}: {e}"
            )
            continue
        db_instance = response["DBInstances"][0]
        db_instance_identifier = db_instance["DBInstanceIdentifier"]
        status = db_instance["DBInstanceStatus"]
        print("The instance {} is in state {}.".format(db_instance_identifier, status))

        if status not in valid_states:
            print("The RDS instance {} needs attention.".format(arn))
            if ENABLE_CLOUDWATCH_METRICS:
                put_custom_metric(
                    cloudwatch=cloudwatch,
                    db_instance_identifier=db_instance_identifier,
                    value=1,
                )
        else:
            print(
                "The RDS cluster {} is in a healthy state, and is reachable and available for use.".format(
                    arn
                )
            )
            if ENABLE_CLOUDWATCH_METRICS:
                put_custom_metric(
                    cloudwatch=cloudwatch,
                    db_instance_identifier=db_instance_identifier,
                    value=0,
                )
    return {"statusCode": 200, "body": "OK"}


def put_custom_metric(cloudwatch, db_instance_identifier: str, value: int):
    return cloudwatch.put_metric_data(
        MetricData=[
            {
                "MetricName": "Status",
                "Dimensions": [
                    {"Name": "DBInstanceIdentifier", "Value": db_instance_identifier},
                ],
                "Unit": "None",
                "Value": value,
            },
        ],
        Namespace="Custom/RDS",
    )
