output "lambda_function_arn" {
  value = aws_lambda_function.generate_image_lambda_32.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.generate_image_queue_32.url
}

output "sns_topic_arn" {
  value = module.sqs_alarm.sns_topic_arn
}
