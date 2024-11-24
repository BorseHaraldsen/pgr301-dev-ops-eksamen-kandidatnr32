resource "aws_sqs_queue" "generate_image_queue_32" {
  name                      = var.sqs_queue_name
  visibility_timeout_seconds = 150
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda_sqs.py"
  output_path = "${path.module}/lambda_sqs.zip"
}

resource "aws_lambda_function" "generate_image_lambda_32" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_role_32.arn
  handler          = "lambda_sqs.lambda_handler"
  runtime          = "python3.8"
  timeout          = 120
  memory_size      = 512
  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      CANDIDATE_NUMBER = var.candidate_number
    }
  }

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
}

resource "aws_iam_role" "lambda_role_32" {
  name = "lambda_sqs_exec_role_32"
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
}

resource "aws_iam_role_policy" "lambda_policy_32" {
  role = aws_iam_role.lambda_role_32.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect = "Allow",
        Resource = aws_sqs_queue.generate_image_queue_32.arn
      },
      {
        Action = [
          "bedrock:InvokeModel"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_mapping_32" {
  event_source_arn = aws_sqs_queue.generate_image_queue_32.arn
  function_name    = aws_lambda_function.generate_image_lambda_32.arn
  batch_size       = 5
  enabled          = true
}

module "sqs_alarm" {
  source          = "./alarm_module_32"
  prefix          = var.candidate_number
  alarm_email     = var.alarm_email
  sqs_queue_name  = var.sqs_queue_name
  threshold       = var.alarm_threshold
}
