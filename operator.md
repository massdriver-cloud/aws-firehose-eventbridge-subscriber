## AWS Kinesis Firehose with EventBridge

Amazon Kinesis Firehose is a fully managed service for real-time loading of streaming data into data lakes, data stores, and analytics services. It can capture, transform, and load streaming data into Amazon S3, Amazon Redshift, Amazon Elasticsearch Service, and Splunk.

This configuration integrates AWS Kinesis Firehose with AWS EventBridge, allowing you to process and store event-driven architecture logs into an S3 bucket.

### Design Decisions

- **Event Triggered:** This design routes events from AWS EventBridge to Kinesis Firehose for processing.
- **Dynamic Partitioning:** Firehose supports dynamic partitioning to organize the data more effectively in the destination S3 bucket.
- **Buffer Settings:** We have optimized the buffer size and interval to suit typical use cases.
- **IAM Policies:** Specific IAM policies ensure secure interaction between EventBridge and Kinesis Firehose.
- **Monitoring:** Cloudwatch alarms are configured for monitoring delivery success and partition sizes.

### Runbook

#### Unable to Trigger EventBridge Rule

This section helps you troubleshoot if the EventBridge rule is not triggering.

Check the EventBridge rule's status:

```sh
aws events describe-rule --name <rule_name>
```

You should see the rule's configuration and its state. If the state is `DISABLED`, enable it:

```sh
aws events enable-rule --name <rule_name>
```

#### Firehose Not Delivering Data to S3

If your Firehose is not delivering data to the S3 bucket, check its delivery stream status.

```sh
aws firehose describe-delivery-stream --delivery-stream-name <stream_name>
```

Look at the `DeliveryStreamStatus` field. If it shows `CREATING` or `DELETING`, wait for the status to change to `ACTIVE`.

For further investigation, check for error messages in CloudWatch logs:

```sh
aws logs describe-log-groups --log-group-name-prefix /aws/kinesisfirehose/<stream_name>
```

You can then retrieve and read the logs for details:

```sh
aws logs get-log-events --log-group-name /aws/kinesisfirehose/<stream_name> --log-stream-name <log_stream>
```

#### Data Delivery Latency

If there is significant delivery latency, check the configured buffer settings:

```sh
aws firehose describe-delivery-stream --delivery-stream-name <stream_name>
```

Make sure `BufferSizeInMBs` and `BufferIntervalInSeconds` match your requirements.

#### Alarm Triggered for Partition Size

Check the details of the CloudWatch alarm that was triggered for partition size:

```sh
aws cloudwatch describe-alarms --alarm-names <alarm_name>
```

Review the metrics and alarm thresholds to understand why it was triggered.

Query the Kinesis Firehose partition metric:

```sh
aws cloudwatch get-metric-statistics --metric-name PartitionCount --namespace AWS/Firehose --statistics Sum --period 300 --dimensions Name=DeliveryStreamName,Value=<stream_name> --start-time <start_time> --end-time <end_time>
```

#### Checking Permissions and Policies

If there are permission issues, verify the IAM policy attached to the EventBridge rule and Firehose delivery stream:

```sh
aws iam get-policy --policy-arn <policy_arn>
```

Ensure it allows necessary actions (`firehose:PutRecord`, `firehose:PutRecordBatch`, etc.). Also, review the attached roles:

```sh
aws iam list-role-policies --role-name <role_name>
```

This will list policies attached to the role; ensure they include permissions for necessary actions.

