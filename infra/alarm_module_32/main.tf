resource "aws_cloudwatch_metric_alarm" "threshold" {
  alarm_name          = "${var.prefix}-sqs-ApproximateAgeOfOldestMessage-alarm"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  dimensions          = { QueueName = var.sqs_queue_name }
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold
  evaluation_periods  = 2
  period              = 30
  statistic           = "Maximum"
  alarm_description   = "Triggers when ApproximateAgeOfOldestMessage exceeds ${var.threshold} seconds."
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
}

resource "aws_sns_topic" "alarm_topic" {
  name = "${var.prefix}-sqs-alarm-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
