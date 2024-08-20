## AWS Kinesis Firehose and EventBridge Integration

Kinesis Firehose is a fully managed service by AWS for reliably loading streaming data into data lakes, data stores, and analytics services. EventBridge is a serverless event bus service that allows you to ingest and process events from a variety of AWS services. The integration of these services helps in efficiently routing and analyzing the real-time event data.

### Design Decisions

1. **Modular Approach**: The integration between AWS Kinesis Firehose and EventBridge is managed through distinct and independently reusable modules.
2. **Dynamic Partitioning**: The Firehose has dynamic partitioning enabled, which allows for controlling the data distribution in real-time, defined through a query.
3. **Automated Monitoring**: Automated alarms are set up for essential metrics such as partition size and S3 delivery success, ensuring reliable and real-time monitoring.
4. **IAM Policies**: Specific IAM policies are created and attached to allow EventBridge to write to Kinesis Firehose securely.
5. **Event Filtering**: EventBridge is set up with customizable event filter patterns to ensure only relevant events are passed to Kinesis Firehose.

### Runbook

#### Firehose Delivery Stream Issues

If you are experiencing issues with your Kinesis Firehose delivery stream, this guide will help you troubleshoot common problems.

##### Unable to Write to Firehose

This issue may occur if the permissions are not correctly set up.

Check the IAM policies and see if they allow the necessary Firehose actions.

```sh
aws iam list-policies --query 'Policies[?PolicyName==`firehose_writer`]'
```

You should see a policy listed that allows `"firehose:PutRecord"` and `"firehose:PutRecordBatch"` actions.

##### Delivery Failures to S3

For instances where Firehose is unable to deliver data to S3, it’s crucial to check the delivery logs.

```sh
aws firehose describe-delivery-stream --delivery-stream-name <your-firehose-name>
```

Review the `Failures` section within the output for any errors and messages that indicate the cause of the failure.

Additionally, verify that the S3 bucket policy allows `PutObject` permissions for the Firehose delivery role.

```sh
aws s3api get-bucket-policy --bucket <your-s3-bucket>
```

##### EventBridge Rule Not Triggering

If your EventBridge rule is not triggering as expected, start by checking the rule configuration.

```sh
aws events describe-rule --name <your-event-rule-name>
```

Make sure the rule is enabled and the event pattern matches the events you are trying to capture.

To check the CloudWatch logs for EventBridge, use:

```sh
aws logs filter-log-events --log-group-name "/aws/events/<your-event-rule-name>"
```

This will show any logs related to your EventBridge rule and aid in troubleshooting.

##### Checking Kinesis Firehose Metrics

For a deeper insight into the performance and issues related to your Kinesis Firehose delivery stream, refer to CloudWatch metrics.

```sh
aws cloudwatch get-metric-statistics --namespace AWS/Firehose --metric-name DeliveryToS3.Records --dimensions Name=DeliveryStreamName,Value=<your-firehose-name> --start-time <start-time> --end-time <end-time> --period 300 --statistics Sum
```

This command will help you gauge how many records are being delivered to S3 over a specific period. Make sure to replace the placeholders with your actual values.

#### Connection Issues for EventBridge and Kinesis Firehose

If you are facing issues with connections or syncing between EventBridge and Kinesis Firehose.

##### EventBridge Target Permission Issues

Ensure EventBridge has the correct permissions to put records into Kinesis Firehose.

```sh
aws events describe-rule --name <your-rule-name> | grep RoleArn
```

Cross-reference the RoleArn with IAM roles to ensure it has the required policies attached.

```sh
aws iam simulate-principal-policy --policy-source-arn <RoleArn> --action-names firehose:PutRecordBatch firehose:PutRecord
```

This will test whether the specified actions are allowed for the role.

By following these troubleshooting steps, you should be able to manage and resolve common issues with your AWS Kinesis Firehose and EventBridge integration.

