output "django_server_public_ip" {
  description = "IP pública del servidor EC2 que corre Django"
  value       = aws_instance.django_server.public_ip
}


## output "api_gateway_url" {
##   # La API la gestionas con Serverless Framework; si la llevas a Terraform, restaura esto.
##   # value = aws_apigatewayv2_api.api.api_endpoint
## }
## Nota: la salida `api_gateway_url` fue comentada porque la API la gestionas con Serverless Framework.