locals {
  automated_alarms = {
    # SUM partition_size <= 80% of Max which is 500
    partition_size = {
      threshold = 80
      period    = 300
    }

    # (s3_delivery_success / s3_requests) >= (.99)
    s3_delivery_success = {
      threshold = 99
      period    = 300
    }
  }

  alarms_map = {
    "AUTOMATED" = local.automated_alarms
    "DISABLED"  = {}
    "CUSTOM"    = lookup(var.monitoring, "alarms", local.automated_alarms)
  }

  alarms                    = lookup(local.alarms_map, var.monitoring.mode, local.automated_alarms)
  create_partitioning_alarm = var.firehose.dynamic_partitioning.enabled && lookup(local.alarms, "partition_size", null) != null
}

module "alarm_channel" {
  source      = "github.com/massdriver-cloud/terraform-modules//aws-alarm-channel?ref=8997456"
  md_metadata = var.md_metadata
}

module "partition_size_alarm" {
  count               = local.create_partitioning_alarm ? 1 : 0
  source              = "github.com/massdriver-cloud/terraform-modules//aws/cloudwatch-alarm?ref=378f3a3"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  alarm_name          = "${var.md_metadata.name_prefix}-Partitioning-Threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  message             = "Kinesis Firehose ${var.md_metadata.name_prefix}: Partition Count > % ${(local.alarms.partition_size.threshold / 100)}"
  display_name        = "Firehose Partition Count"
  metric_name         = "PartitionCount"
  namespace           = "AWS/Firehose"
  period              = local.alarms.partition_size.period
  statistic           = "Sum"
  threshold           = 500 * (local.alarms.partition_size.threshold / 100)
  dimensions = {
    DeliveryStreamName = var.md_metadata.name_prefix
  }
}

module "s3_delivery_alarm" {
  count               = lookup(local.alarms, "s3_delivery_success", null) == null ? 0 : 1
  source              = "github.com/massdriver-cloud/terraform-modules//aws/cloudwatch-alarm-expression?ref=29df3b2"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  alarm_name          = "${var.md_metadata.name_prefix}-S3-Delivery-Success"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  message             = "Kinesis Firehose ${var.md_metadata.name_prefix}: Error Rate > ${(local.alarms.s3_delivery_success.threshold / 100)}%"
  display_name        = "Firehose S3 Delivery Errors"
  threshold           = local.alarms.s3_delivery_success.threshold / 100
  display_metric_key  = "m2"

  metric_queries = {
    m1 = {
      metric = {
        metric_name = "DeliveryToS3.Records"
        namespace   = "AWS/Firehose"
        period      = local.alarms.s3_delivery_success.period
        stat        = "Average"
        dimensions = {
          DeliveryStreamName = var.md_metadata.name_prefix
        }
      }
    }

    m2 = {
      metric = {
        metric_name = "DeliveryToS3.Success"
        namespace   = "AWS/Firehose"
        period      = local.alarms.s3_delivery_success.period
        stat        = "Average"
        dimensions = {
          DeliveryStreamName = var.md_metadata.name_prefix
        }
      }
    }

    m3 = {
      expression  = "m2 / m1"
      label       = "Success Rate"
      return_data = true
    }
  }
}
