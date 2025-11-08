/* --- HTTP Lambdas (auth + API handlers) --- */
resource "aws_lambda_function" "login" {
  function_name = "${var.project_name}-${var.environment}-login"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/auth.login"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USER_POOL_CLIENT_ID   = aws_cognito_user_pool_client.main.id
      DYNAMODB_TABLE        = aws_dynamodb_table.main.name
      HOSPITAL_DATA_TABLE   = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "refresh" {
  function_name = "${var.project_name}-${var.environment}-refresh"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/auth.refresh"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USER_POOL_CLIENT_ID   = aws_cognito_user_pool_client.main.id
    }
  }
}

resource "aws_lambda_function" "me" {
  function_name = "${var.project_name}-${var.environment}-me"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/auth.me"
  runtime       = var.lambda_runtime
  timeout       = 5
  memory_size   = 128

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_function" "get_boxes" {
  function_name = "${var.project_name}-${var.environment}-get-boxes"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/boxes.getBoxes"
  runtime       = var.lambda_runtime
  timeout       = 20
  memory_size   = 512

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.main.name
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "get_agendas" {
  function_name = "${var.project_name}-${var.environment}-get-agendas"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/agendas.getAgendas"
  runtime       = var.lambda_runtime
  timeout       = 20
  memory_size   = 512

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.main.name
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "create_agenda" {
  function_name = "${var.project_name}-${var.environment}-create-agenda"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/agendas.createAgenda"
  runtime       = var.lambda_runtime
  timeout       = 30
  memory_size   = 512

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.main.name
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "get_pasillos" {
  function_name = "${var.project_name}-${var.environment}-get-pasillos"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/pasillos.getPasillos"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE      = aws_dynamodb_table.main.name
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "list_clients" {
  function_name = "${var.project_name}-${var.environment}-list-clients"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/personalization.listClients"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "get_client_config" {
  function_name = "${var.project_name}-${var.environment}-get-client-config"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/personalization.getClientConfig"
  runtime       = var.lambda_runtime
  timeout       = 10
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

resource "aws_lambda_function" "update_client_config" {
  function_name = "${var.project_name}-${var.environment}-update-client-config"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "src/handlers/personalization.updateClientConfig"
  runtime       = var.lambda_runtime
  timeout       = 20
  memory_size   = 256

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      HOSPITAL_DATA_TABLE = aws_dynamodb_table.main.name
    }
  }
}

/* --- API Gateway integrations & routes --- */
resource "aws_apigatewayv2_integration" "login_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.login.invoke_arn
}

resource "aws_apigatewayv2_route" "login_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.login_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_login" {
  statement_id  = "AllowAPIGatewayInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

/* Repeat integration/route/permission for other endpoints */
resource "aws_apigatewayv2_integration" "refresh_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.refresh.invoke_arn
}
resource "aws_apigatewayv2_route" "refresh_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /auth/refresh"
  target    = "integrations/${aws_apigatewayv2_integration.refresh_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_refresh" {
  statement_id  = "AllowAPIGatewayInvokeRefresh"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.refresh.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "me_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.me.invoke_arn
}
resource "aws_apigatewayv2_route" "me_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /me"
  target    = "integrations/${aws_apigatewayv2_integration.me_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_me" {
  statement_id  = "AllowAPIGatewayInvokeMe"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.me.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

/* Boxes */
resource "aws_apigatewayv2_integration" "getboxes_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_boxes.invoke_arn
}
resource "aws_apigatewayv2_route" "getboxes_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/boxes"
  target    = "integrations/${aws_apigatewayv2_integration.getboxes_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_getboxes" {
  statement_id  = "AllowAPIGatewayInvokeGetBoxes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_boxes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

/* Agendas list/create */
resource "aws_apigatewayv2_integration" "getagendas_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_agendas.invoke_arn
}
resource "aws_apigatewayv2_route" "getagendas_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/agendas"
  target    = "integrations/${aws_apigatewayv2_integration.getagendas_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_getagendas" {
  statement_id  = "AllowAPIGatewayInvokeGetAgendas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_agendas.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "createagenda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_agenda.invoke_arn
}
resource "aws_apigatewayv2_route" "createagenda_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/agendas"
  target    = "integrations/${aws_apigatewayv2_integration.createagenda_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_createagenda" {
  statement_id  = "AllowAPIGatewayInvokeCreateAgenda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_agenda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

/* Pasillos */
resource "aws_apigatewayv2_integration" "getpasillos_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_pasillos.invoke_arn
}
resource "aws_apigatewayv2_route" "getpasillos_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/pasillos"
  target    = "integrations/${aws_apigatewayv2_integration.getpasillos_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_getpasillos" {
  statement_id  = "AllowAPIGatewayInvokeGetPasillos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_pasillos.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

/* Personalization endpoints */
resource "aws_apigatewayv2_integration" "listclients_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.list_clients.invoke_arn
}
resource "aws_apigatewayv2_route" "listclients_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/config"
  target    = "integrations/${aws_apigatewayv2_integration.listclients_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_listclients" {
  statement_id  = "AllowAPIGatewayInvokeListClients"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_clients.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "getclientconfig_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_client_config.invoke_arn
}
resource "aws_apigatewayv2_route" "getclientconfig_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/config/{clientId}"
  target    = "integrations/${aws_apigatewayv2_integration.getclientconfig_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_getclientconfig" {
  statement_id  = "AllowAPIGatewayInvokeGetClientConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_client_config.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "updateclientconfig_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.update_client_config.invoke_arn
}
resource "aws_apigatewayv2_route" "updateclientconfig_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /api/config/{clientId}"
  target    = "integrations/${aws_apigatewayv2_integration.updateclientconfig_integration.id}"
}
resource "aws_lambda_permission" "allow_apigw_updateclientconfig" {
  statement_id  = "AllowAPIGatewayInvokeUpdateClientConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_client_config.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}