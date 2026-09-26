# QUEST 009：通知を分配せよ

## 🎯 目的

Amazon SNSを使って1つのメッセージを複数のSQS Queueへ配信し、Fan-outとSubscription Filterの動きを確認する。

## 🧩 構成

```text
                  ┌─ Subscription ─→ SQS Queue A
                  │
Publisher ─→ SNS Topic
                  │
                  └─ Subscription ─→ SQS Queue B
```

SNS Topicへ1回Publishしたメッセージが、2つのSQS Queueへそれぞれ配信される構成をTerraformで作成した。

## 🛠️ 作成したリソース

- SNS Topic
- SQS Queue × 2
- SNS Topic Subscription × 2
- SQS Queue Policy × 2

## 🔐 SNS → SQSの権限

SQS Queue PolicyでSNSからの `sqs:SendMessage` を許可した。

```text
SNS Topic
    │
    │ sqs:SendMessage
    ▼
SQS Queue
```

PrincipalはSNSサービスに限定し、さらに `aws:SourceArn` で今回作成したSNS Topicだけに制限した。

IAM Roleは作成せず、SQSのResource-based Policyでアクセスを制御した。

## 🧪 Fan-out確認

SNS Topicから1回メッセージをPublish。

```text
              SNS Topic
                 │
          ┌──────┴──────┐
          ▼             ▼
      SQS Queue A   SQS Queue B
          📨             📨
```

両方のQueueにメッセージが1件ずつ届くことを確認した。

これにより、SNSでは1つのメッセージを複数のSubscriberへ配信できることを確認した。

## 📦 SQSに届くメッセージ

SQSコンソールからメッセージをポーリングして内容を確認した。

SNSからSQSへ配信した場合、Publishした本文だけではなく、SNSの情報を含んだJSON形式のメッセージとして届くことを確認した。

そのため、

```text
SNS
 ↓
SQS
 ↓
Lambda
```

のようにサービスを連携する場合は、経由するサービスによってイベントの構造が変わることに注意する。

## 🔍 Subscription Filter

Queue AのSubscriptionにFilter Policyを設定した。

```hcl
filter_policy = jsonencode({
  eventType = ["a"]
})
```

Queue BにはFilter Policyを設定しなかった。

### eventType = a

```text
SNS
 ├─→ Queue A 📨
 └─→ Queue B 📨
```

両方に配信された。

### eventType = b

```text
SNS
 ├─→ Queue A ×
 └─→ Queue B 📨
```

Queue AではFilter条件に一致しないため配信されず、Queue Bだけに配信された。

### eventTypeなし

```text
SNS
 ├─→ Queue A ×
 └─→ Queue B 📨
```

Filter Policyで使用するMessage Attribute自体が存在しないため、Queue Aには配信されなかった。

## 💡 EventBridgeとの違い

QUEST 007ではEventBridge Ruleによるイベントフィルタを確認した。

```text
Event
 ↓
EventBridge Rule
 ↓ 条件判定
Target
```

SNSではSubscriptionごとにFilter Policyを設定できる。

```text
             ┌─ Filter A → Subscriber A
SNS Topic ───┤
             └─ Filter B → Subscriber B
```

EventBridgeはイベントを条件に応じてルーティングする。

SNSは1つのメッセージを複数のSubscriberへ配信し、それぞれのSubscriptionで受信するメッセージを選別できる。

## 🆚 SQSとの違い

QUEST 008ではSQSが処理対象のメッセージを保持することを確認した。

```text
SQS = 預かる
SNS = 配る
```

SQSでは処理側が停止していてもQueueにメッセージを保持できる。

SNSでは1回Publishしたメッセージを複数のSubscriberへFan-outできる。

組み合わせることで、

```text
                  ┌→ SQS A → Consumer A
Publisher → SNS ──┤
                  └→ SQS B → Consumer B
```

のように、メッセージを複数系統へ分配し、それぞれのQueueで保持・処理できる。

## 💥 ハマり・気づき

- SNS → SQSではLambda Event Source Mappingは不要
- SNSからSQSへの送信許可はSQS Queue Policyで設定する
- IAM Roleを必ず作るわけではなくResource-based Policyで連携できる
- `aws:SourceArn` で許可するSNS Topicを限定できる
- SNSからSQSへ届くメッセージはSNSの情報を含むJSON形式になる
- Subscription FilterはSubscriberごとに設定できる
- デフォルトのFilter PolicyではMessage Attributesを条件として使用する
- SQSの「保持」とSNSの「分配」は役割が異なる

## 🏁 RESULT

CLEAR