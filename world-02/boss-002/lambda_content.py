import json
import urllib.parse
import boto3

s3 = boto3.client("s3")

def lambda_handler(event, context):
    failures = []
    for message in event["Records"]:
        try:
            notification = json.loads(message["body"])
            if notification.get("Event") == "s3:TestEvent":
                print("S3 test event ignored")
                continue
            for record in notification["Records"]:
                bucket = record["s3"]["bucket"]["name"]
                key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
                body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8")
                print(json.dumps({"bucket": bucket, "key": key, "content": body}, ensure_ascii=False))
        except Exception as exc:
            print(f"content processing failed: {exc}")
            failures.append({"itemIdentifier": message["messageId"]})
    return {"batchItemFailures": failures}
