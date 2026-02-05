output "api_role_arn" {
  value = aws_iam_role.api_role.arn
}

output "worker_role_arn" {
  value = aws_iam_role.worker_role.arn
}

output "api_lambda_arn" {
  value = aws_lambda_function.api.arn
}

output "worker_lambda_arn" {
  value = aws_lambda_function.worker.arn
}

output "api_ecr_repo_url" {
  value = aws_ecr_repository.api.repository_url
}

output "worker_ecr_repo_url" {
  value = aws_ecr_repository.worker.repository_url
}

output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "meta_bucket_name" {
  value = aws_s3_bucket.meta.bucket
}

output "profile_bucket_name" {
  value = aws_s3_bucket.profiles.bucket
}

output "queue_url_blue" {
  value = aws_sqs_queue.worker_blue.id
}

output "queue_url_green" {
  value = aws_sqs_queue.worker_green.id
}

output "queue_url_dlq" {
  value = aws_sqs_queue.worker_dlq.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alarms.arn
}

output "api_invoke_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "apigw_access_log_group" {
  value = aws_cloudwatch_log_group.apigw_access.name
}

output "alarm_api_errors" {
  value = aws_cloudwatch_metric_alarm.api_errors.alarm_name
}

output "alarm_api_duration_p95" {
  value = aws_cloudwatch_metric_alarm.api_duration_p95.alarm_name
}

output "alarm_api_throttles" {
  value = aws_cloudwatch_metric_alarm.api_throttles.alarm_name
}

output "alarm_worker_errors" {
  value = aws_cloudwatch_metric_alarm.worker_errors.alarm_name
}

output "alarm_worker_duration_p95" {
  value = aws_cloudwatch_metric_alarm.worker_duration_p95.alarm_name
}

output "alarm_worker_throttles" {
  value = aws_cloudwatch_metric_alarm.worker_throttles.alarm_name
}

output "alarm_dlq_messages" {
  value = aws_cloudwatch_metric_alarm.dlq_messages.alarm_name
}

output "alarm_queue_age" {
  value = aws_cloudwatch_metric_alarm.queue_age.alarm_name
}
