/* User Events Handler */
resource "aws_lambda_function" "user_events_handler" {
  function_name = "${var.project_name}-${var.environment}-user-events-handler"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/user-events-handler.handleUserEvents"
  runtime       = var.lambda_runtime
  timeout       = 30
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE          = aws_dynamodb_table.main.name
      USER_EVENTS_TOPIC_ARN   = aws_sns_topic.user_events.arn
      AGENDA_EVENTS_TOPIC_ARN = aws_sns_topic.agenda_events.arn
      NOTIFICATIONS_TOPIC_ARN = aws_sns_topic.notifications.arn
      BOX_EVENTS_TOPIC_ARN    = aws_sns_topic.box_events.arn
    }
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-user-events-handler" })
}

/* Agenda Events Handler */
resource "aws_lambda_function" "agenda_events_handler" {
  function_name = "${var.project_name}-${var.environment}-agenda-events-handler"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/agenda-events-handler.handleAgendaEvents"
  runtime       = var.lambda_runtime
  timeout       = 30
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE          = aws_dynamodb_table.main.name
      NOTIFICATIONS_TOPIC_ARN = aws_sns_topic.notifications.arn
      BOX_EVENTS_TOPIC_ARN    = aws_sns_topic.box_events.arn
    }
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-agenda-events-handler" })
}

/* Notification Handler */
resource "aws_lambda_function" "notification_handler" {
  function_name = "${var.project_name}-${var.environment}-notification-handler"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/notification-handler.handleNotifications"
  runtime       = var.lambda_runtime
  timeout       = 30
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.main.name
    }
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-notification-handler" })
}

/* Setup test users (Custom Resource Lambda). Longer timeout as in serverless.yml */
resource "aws_lambda_function" "setup_test_users" {
  function_name = "${var.project_name}-${var.environment}-setup-test-users"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/setup-test-users.handler"
  runtime       = var.lambda_runtime
  timeout       = 300
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
    }
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-setup-test-users" })
}

/* SNS -> Lambda subscriptions and permissions */

resource "aws_lambda_permission" "allow_sns_invoke_user_events" {
  statement_id  = "AllowSNSInvokeUserEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_events_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_events.arn
}

resource "aws_lambda_permission" "allow_sns_invoke_agenda_events" {
  statement_id  = "AllowSNSInvokeAgendaEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agenda_events_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.agenda_events.arn
}

resource "aws_lambda_permission" "allow_sns_invoke_notifications" {
  statement_id  = "AllowSNSInvokeNotifications"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.notifications.arn
}

/* Subscriptions */
resource "aws_sns_topic_subscription" "user_events_to_lambda" {
  topic_arn = aws_sns_topic.user_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.user_events_handler.arn
}

resource "aws_sns_topic_subscription" "agenda_events_to_lambda" {
  topic_arn = aws_sns_topic.agenda_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.agenda_events_handler.arn
}

resource "aws_sns_topic_subscription" "notifications_to_lambda" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notification_handler.arn
}

/* Note: box_events topic currently has no direct subscriber defined in serverless.yml; add if needed later */
