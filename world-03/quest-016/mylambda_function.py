import os
import boto3

def lambda_handler(event, context):
    client = boto3.client("secretsmanager")

    response = client.get_secret_value(
        SecretId=os.environ["SECRET_NAME"]
    )

    return {
        "status": "success",
        "message": "Secret retrieved successfully"
    }