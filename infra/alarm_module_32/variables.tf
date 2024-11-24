variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "candidate32"
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "terraform-sqs-queue-32"
}

variable "threshold" {
  description = "Threshold for ApproximateAgeOfOldestMessage (seconds)"
  default     = 30
  type        = number
}
