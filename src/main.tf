locals {
  filter_pattern             = var.event_rule.event_filter == "all" ? "{}" : var.event_rule.event_filter_pattern
  dynamic_partitioning_query = lookup(var.firehose.dynamic_partitioning, "query", "")
}

module "firehose" {
  source                       = "github.com/massdriver-cloud/terraform-modules//aws/aws-kinesis-firehose?ref=d4b66db"
  name                         = var.md_metadata.name_prefix
  dynamic_partitioning_enabled = var.firehose.dynamic_partitioning.enabled
  query                        = local.dynamic_partitioning_query
  destination                  = "s3"
  buffer_size_mb               = var.firehose.buffer_size
  buffer_interval_seconds      = var.firehose.buffer_interval
  bucket_arn                   = var.event_destination.data.infrastructure.arn
  write_policy_arn             = var.event_destination.data.security.iam.write.policy_arn
}

module "event_rule" {
  source               = "github.com/massdriver-cloud/terraform-modules//aws/aws-eventbridge-rule?ref=d4b66db"
  name                 = var.md_metadata.name_prefix
  event_filter         = var.event_rule.event_filter
  event_filter_pattern = local.filter_pattern
  target_resource_arn  = module.firehose.arn
  event_bus_arn        = var.event_source.data.infrastructure.arn
}

resource "aws_iam_policy" "firehose_writer" {
  name        = "${var.md_metadata.name_prefix}-firehose-writer"
  description = "Permits writing to Firehose from Eventbridge's event rules"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
        Effect   = "Allow"
        Resource = module.firehose.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eventbridge" {
  name       = "${var.md_metadata.name_prefix}-eventbridge-rule-attachment"
  roles      = [module.event_rule.role_name]
  policy_arn = aws_iam_policy.firehose_writer.arn
}
