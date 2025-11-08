// IAM resources
data "aws_iam_role" "lab" {
  # Rol preexistente provisto por el laboratorio/administración. Se usa cuando
  # `create_iam_resources` está deshabilitado.
  name = "LabRole"
}

resource "aws_iam_role" "lambda_exec_role" {
  count = var.create_iam_resources ? 1 : 0

  name = "${var.project_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "lambda_policy" {
  count = var.create_iam_resources ? 1 : 0

  name        = "${var.project_name}-lambda-policy"
  description = "Least-privilege policy for Lambdas (DynamoDB, SNS, CloudWatch Logs)"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish",
          "sns:ListTopics"
        ],
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  count = var.create_iam_resources ? 1 : 0

  role       = aws_iam_role.lambda_exec_role[0].name
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}

// Exporta la ARN del role que las Lambdas deberían usar. Si Terraform creó
// el role, devolvemos esa ARN; si no, devolvemos la ARN del rol `LabRole`.
output "lambda_exec_role_arn" {
  description = "ARN del role de ejecución para Lambdas (creado o existente)"
  value       = try(aws_iam_role.lambda_exec_role[0].arn, data.aws_iam_role.lab.arn)
}
