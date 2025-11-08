resource "aws_dynamodb_table" "main" {
  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_billing_mode

  # Keys
  hash_key  = "PK"
  range_key = "SK"

  # Attributes
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # Global Secondary Index
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  # Streams
  stream_enabled   = var.enable_dynamodb_streams
  stream_view_type = var.enable_dynamodb_streams ? "NEW_AND_OLD_IMAGES" : null

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_dynamodb_pitr
  }

  # TTL (opcional)
  ttl {
    enabled        = false
    attribute_name = ""
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-dynamodb"
    }
  )
}
