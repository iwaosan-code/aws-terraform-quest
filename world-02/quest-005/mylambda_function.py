import json

def lambda_handler(event, context):
    print ("Lambdaが起動しました ver2")

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda! (Python)')
    }