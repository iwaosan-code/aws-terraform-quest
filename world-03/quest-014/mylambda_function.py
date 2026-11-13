import json

def lambda_handler(event, context):
    for record in event['Records']:
        event_name = record['eventName']
        dynamodb= record['dynamodb']

        print(json.dumps({
            "event_name": event_name,
            "Keys": dynamodb.get('Keys'),
            "OldImage": dynamodb.get("OldImage"),
            "NewImage": dynamodb.get("NewImage")
        }))

    return {"statusCode": 200}