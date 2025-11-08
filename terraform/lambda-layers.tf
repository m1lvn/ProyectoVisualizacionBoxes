variable "create_lambda_layers" {
  type    = bool
  default = false
}

resource "aws_lambda_layer_version" "node_modules" {
  count = var.create_lambda_layers ? 1 : 0

  filename            = "${path.module}/lambda_node_modules.zip"
  layer_name          = "${var.project_name}-${var.environment}-node-modules"
  compatible_runtimes = [var.lambda_runtime]

  description = "Node modules layer for ${var.project_name} (${var.environment})"

  lifecycle {
    create_before_destroy = true
  }

  # Tagging of Layer resources is not supported by all provider versions.
  # If you need tags, attach them at the Lambda function level instead.
}

/* Package helper (not executed by Terraform). Keep the archive filename consistent with the resource. */
// To build the layer zip run (manually):
// cd serverless-api && zip -r ../terraform/lambda_node_modules.zip node_modules
