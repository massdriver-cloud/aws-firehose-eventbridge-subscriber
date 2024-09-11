// Auto-generated variable declarations from massdriver.yaml
variable "aws_authentication" {
  type = object({
    data = object({
      arn         = string
      external_id = optional(string)
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}
variable "event_destination" {
  type = object({
    data = object({
      infrastructure = object({
        arn = string
      })
      security = optional(object({
        iam = optional(map(object({
          policy_arn = string
        })))
        identity = optional(object({
          role_arn = optional(string)
        }))
        network = optional(map(object({
          arn      = string
          port     = number
          protocol = string
        })))
      }))
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}
variable "event_rule" {
  type = object({
    event_filter         = optional(string)
    event_filter_pattern = optional(string)
  })
}
variable "event_source" {
  type = object({
    data = object({
      infrastructure = object({
        arn = string
      })
      security = optional(object({
        iam = optional(map(object({
          policy_arn = string
        })))
        identity = optional(object({
          role_arn = optional(string)
        }))
        network = optional(map(object({
          arn      = string
          port     = number
          protocol = string
        })))
      }))
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}
variable "firehose" {
  type = object({
    buffer_interval_seconds = number
    buffer_size_mb          = number
    dynamic_partitioning = optional(object({
      enabled = bool
      query   = optional(string)
    }))
  })
}
variable "md_metadata" {
  type = object({
    default_tags = object({
      managed-by  = string
      md-manifest = string
      md-package  = string
      md-project  = string
      md-target   = string
    })
    deployment = object({
      id = string
    })
    name_prefix = string
    observability = object({
      alarm_webhook_url = string
    })
    package = object({
      created_at             = string
      deployment_enqueued_at = string
      previous_status        = string
      updated_at             = string
    })
    target = object({
      contact_email = string
    })
  })
}
variable "monitoring" {
  type = object({
    mode = optional(string)
    alarms = optional(object({
      partition_size = optional(object({
        period    = number
        threshold = number
      }))
      s3_delivery_success = optional(object({
        period    = number
        threshold = number
      }))
    }))
  })
}
