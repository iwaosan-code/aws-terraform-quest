import json
import urllib.parse

def lambda_handler(event, context):
    failures = []
    for message in event["Records"]:
        try:
            notification = json.loads(message["body"])
            if notification.get("Event") == "s3:TestEvent":
                print("S3 test event ignored")
                continue
            for record in notification["Records"]:
                print(json.dumps({
                    "event": record["eventName"],
                    "bucket": record["s3"]["bucket"]["name"],
                    "key": urllib.parse.unquote_plus(record["s3"]["object"]["key"])
                }, ensure_ascii=False))
        except Exception as exc:
            print(f"audit processing failed: {exc}")
            failures.append({"itemIdentifier": message["messageId"]})
    return {"batchItemFailures": failures}
