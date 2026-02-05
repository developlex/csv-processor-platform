variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
