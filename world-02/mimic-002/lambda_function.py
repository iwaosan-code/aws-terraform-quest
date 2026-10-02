def lambda_handler(event, context):
    print("MIMIC: わざと処理を失敗させます")
    raise Exception("MIMIC: intentional failure")