variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "project_name" {
  description = "Short project identifier for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "raw_bucket_name" {
  description = "S3 bucket for raw CSV uploads"
  type        = string
}

variable "meta_bucket_name" {
  description = "S3 bucket for metadata"
  type        = string
}

variable "profile_bucket_name" {
  description = "S3 bucket for profiles"
  type        = string
}

variable "queue_name_blue" {
  description = "SQS queue name for blue worker"
  type        = string
  default     = "worker-blue"
}

variable "queue_name_green" {
  description = "SQS queue name for green worker"
  type        = string
  default     = "worker-green"
}

variable "queue_name_dlq" {
  description = "SQS dead-letter queue name"
  type        = string
  default     = "worker-dlq"
}

variable "sns_topic_name" {
  description = "SNS topic name for alarms"
  type        = string
  default     = "csv-processor-alarms"
}

variable "log_group_api_name" {
  description = "CloudWatch log group name for API Lambda"
  type        = string
  default     = "/aws/lambda/csv-processor-api"
}

variable "log_group_worker_name" {
  description = "Cloudwatch log group name for worker Lambda"
  type        = string
  default     = "/aws/lambda/csv-processor-worker"
}

variable "log_retention_days" {
  description = "Cloudwatch log retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "api_ecr_repo_name" {
  description = "ECR repo name for API image"
  type        = string
  default     = "csv-processor-api"
}

variable "worker_ecr_repo_name" {
  description = "ECR repo name for Worker image"
  type        = string
  default     = "csv-processor-worker"
}

variable "image_tag" {
  description = "Container image tag (e.g., dev, latest, commit SHA)"
  type        = string
  default     = "dev"
}

variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "csv-processor-api"
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "api_gateway_log_retention_days" {
  description = "CloudWatch log retention for API Gateway access logs"
  type        = number
  default     = 7
}

variable "apigw_log_role_name" {
  description = "IAM role name for API Gateway to write CloudWatch Logs"
  type        = string
  default     = "apigw-cloudwatch-logs-role"
}


variable "lambda_memory_mb" {
  description = "Lambda memory for API and Worker"
  type        = number
  default     = 2048
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout for API and Worker"
  type        = number
  default     = 180
}

variable "worker_traffic_split" {
  description = "Percent of new dataset_ids routed to green (0-100)"
  type        = number
  default     = 0
}
