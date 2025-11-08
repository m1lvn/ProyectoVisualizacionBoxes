output "django_server_public_ip" {
  description = "IP pública del servidor EC2 que corre Django"
  value       = aws_instance.django_server.public_ip
}

output "cognito_user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN del Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint del Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "cognito_client_id" {
  description = "ID del Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB principal"
  value       = aws_dynamodb_table.main.name
}

output "sns_user_events_arn" {
  description = "ARN del SNS topic user events"
  value       = aws_sns_topic.user_events.arn
}

output "sns_agenda_events_arn" {
  description = "ARN del SNS topic agenda events"
  value       = aws_sns_topic.agenda_events.arn
}

output "sns_notifications_arn" {
  description = "ARN del SNS topic notifications"
  value       = aws_sns_topic.notifications.arn
}

output "sns_box_events_arn" {
  description = "ARN del SNS topic box events"
  value       = aws_sns_topic.box_events.arn
}


## output "api_gateway_url" {
##   # La API la gestionas con Serverless Framework; si la llevas a Terraform, restaura esto.
##   # value = aws_apigatewayv2_api.api.api_endpoint
## }
## Nota: la salida `api_gateway_url` fue comentada porque la API la gestionas con Serverless Framework.