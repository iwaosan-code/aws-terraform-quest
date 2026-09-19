import json
import urllib.parse
import boto3

# S3クライアントの初期化
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # S3イベントからバケット名とオブジェクトキーを取得
    try:
        # S3イベント通知レコードは配列
        record = event['Records'][0]

        bucket_name = record['s3']['bucket']['name']
        # ファイル名にスペースや日本語が含まれる場合のエンコード対策
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])

        print(f"対象バケット: {bucket_name}")
        print(f"対象オブジェクト: {key}")

        # S3からオブジェクトを取得
        response = s3_client.get_object(Bucket=bucket_name, Key=key)

        # オブジェクトの中身を取得してテキストにデコード
        content = response['Body'].read().decode('utf-8')

        # CloudWatch Logsに出力
        print("--- ファイルの中身（ここから） ---")
        print(content)
        print("--- ファイルの中身（ここまで） ---")

        return  {
            'statusCode': 200,
            'body': json.dumps('S3オブジェクトの取得に成功しました。')
        }

    except Exception as e:
        print(f"エラーが発生しました: {str(e)}")
        raise e