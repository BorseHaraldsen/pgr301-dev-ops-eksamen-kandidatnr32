output "sns_topic_arn" {
  value       = aws_sns_topic.alarm_topic.arn
}

output "alarm_name" {
  description = "The name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.threshold.alarm_name
}

output "alarm_arn" {
  description = "The ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.threshold.arn
}