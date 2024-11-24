variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "sam-lambda-terraform-messaging-version-32"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for AI images generated"
  type        = string
  default     = "pgr301-couch-explorers"
}

variable "candidate_number" {
  description = "exam number provided"
  type        = string
  default     = "32"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "terraform-sqs-queue-32"
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "alarm_threshold" {
  description = "Threshold for ApproximateAgeOfOldestMessage in seconds"
  default     = 30
  type        = number
}
