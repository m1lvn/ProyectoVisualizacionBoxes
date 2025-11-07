output "django_server_public_ip" {
  value = aws_instance.django_server.public_ip
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}