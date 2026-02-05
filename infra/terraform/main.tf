data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "api_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${var.raw_bucket_name}/raw/*",
      "arn:aws:s3:::${var.meta_bucket_name}/meta/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.worker_blue.arn,
      aws_sqs_queue.worker_green.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alarms.arn]
  }
}

data "aws_iam_policy_document" "worker_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.raw_bucket_name}/raw/*",
      "arn:aws:s3:::${var.meta_bucket_name}/meta/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${var.meta_bucket_name}/meta/*",
      "arn:aws:s3:::${var.profile_bucket_name}/profiles/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.worker_blue.arn,
      aws_sqs_queue.worker_green.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alarms.arn]
  }
}

data "aws_iam_policy_document" "apigw_log_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

locals {
  ecr_untagged_rule = {
    rulePriority = 1
    description  = "Expire untagged images after 7 days"
    selection = {
      tagStatus   = "untagged"
      countType   = "sinceImagePushed"
      countUnit   = "days"
      countNumber = 7
    }
    action = {
      type = "expire"
    }
  }

  ecr_tagged_rule = {
    rulePriority = 2
    description  = "Keep last 20 tagged images"
    selection = {
      tagStatus   = "tagged"
      countType   = "imageCountMoreThan"
      countNumber = 20
    }
    action = {
      type = "expire"
    }
  }

  ecr_rules = [
    local.ecr_untagged_rule,
    local.ecr_tagged_rule
  ]
}

resource "aws_s3_bucket" "raw" {
  bucket = var.raw_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket" "meta" {
  bucket = var.meta_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket" "profiles" {
  bucket = var.profile_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "meta" {
  bucket = aws_s3_bucket.meta.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "profiles" {
  bucket = aws_s3_bucket.profiles.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "meta" {
  bucket = aws_s3_bucket.meta.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "profiles" {
  bucket = aws_s3_bucket.profiles.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "meta" {
  bucket                  = aws_s3_bucket.meta.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "profiles" {
  bucket                  = aws_s3_bucket.profiles.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ecr_repository" "api" {
  name = "${var.project_name}-${var.environment}-${var.api_ecr_repo_name}"
  tags = var.tags
}

resource "aws_ecr_repository" "worker" {
  name = "${var.project_name}-${var.environment}-${var.worker_ecr_repo_name}"
  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = local.ecr_rules
  })
}

resource "aws_ecr_lifecycle_policy" "worker" {
  repository = aws_ecr_repository.worker.name

  policy = jsonencode({
    rules = local.ecr_rules
  })
}

resource "aws_sqs_queue" "worker_dlq" {
  name = var.queue_name_dlq
  tags = var.tags
}

resource "aws_sqs_queue" "worker_blue" {
  name = var.queue_name_blue
  tags = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.worker_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "worker_green" {
  name = var.queue_name_green
  tags = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.worker_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_role" "api_role" {
  name               = "${var.project_name}-${var.environment}-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "api_policy" {
  name   = "${var.project_name}-${var.environment}-api-policy"
  role   = aws_iam_role.api_role.id
  policy = data.aws_iam_policy_document.api_policy.json
}

resource "aws_iam_role" "worker_role" {
  name               = "${var.project_name}-${var.environment}-worker-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "worker_policy" {
  name   = "${var.project_name}-${var.environment}-worker-policy"
  role   = aws_iam_role.worker_role.id
  policy = data.aws_iam_policy_document.worker_policy.json
}

resource "aws_iam_role" "apigw_log_role" {
  name               = "${var.project_name}-${var.environment}-${var.apigw_log_role_name}"
  assume_role_policy = data.aws_iam_policy_document.apigw_log_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "apigw_log_role_attach" {
  role       = aws_iam_role.apigw_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-${var.environment}-api"
  role          = aws_iam_role.api_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  publish = true

  environment {
    variables = {
      RAW_BUCKET           = var.raw_bucket_name
      META_BUCKET          = var.meta_bucket_name
      PROFILE_BUCKET       = var.profile_bucket_name
      QUEUE_URL_BLUE       = aws_sqs_queue.worker_blue.id
      QUEUE_URL_GREEN      = aws_sqs_queue.worker_green.id
      AWS_REGION           = var.aws_region
      ALARM_TOPIC_ARN      = aws_sns_topic.alarms.arn
      WORKER_TRAFFIC_SPLIT = tostring(var.worker_traffic_split)
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "worker" {
  function_name = "${var.project_name}-${var.environment}-worker"
  role          = aws_iam_role.worker_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.worker.repository_url}:${var.image_tag}"

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  publish = true

  environment {
    variables = {
      RAW_BUCKET           = var.raw_bucket_name
      META_BUCKET          = var.meta_bucket_name
      PROFILE_BUCKET       = var.profile_bucket_name
      QUEUE_URL_BLUE       = aws_sqs_queue.worker_blue.id
      QUEUE_URL_GREEN      = aws_sqs_queue.worker_green.id
      AWS_REGION           = var.aws_region
      ALARM_TOPIC_ARN      = aws_sns_topic.alarms.arn
      WORKER_TRAFFIC_SPLIT = tostring(var.worker_traffic_split)
    }
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "worker_blue" {
  event_source_arn = aws_sqs_queue.worker_blue.arn
  function_name    = aws_lambda_alias.worker_live.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "worker_green" {
  event_source_arn = aws_sqs_queue.worker_green.arn
  function_name    = aws_lambda_alias.worker_live.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_alias" "api_live" {
  name             = "api-live"
  function_name    = aws_lambda_function.api.function_name
  function_version = aws_lambda_function.api.version
}

resource "aws_lambda_alias" "worker_live" {
  name             = "worker-live"
  function_name    = aws_lambda_function.worker.function_name
  function_version = aws_lambda_function.worker.version
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-${var.environment}-${var.api_gateway_name}"
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "api_lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.api_live.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.api_gateway_stage
  auto_deploy = true
  tags        = var.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access.arn
    format = jsonencode({
      requestId   = "$context.requestId"
      ip          = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod  = "$context.httpMethod"
      routeKey    = "$context.routeKey"
      status      = "$context.status"
      protocol    = "$context.protocol"
      responseLen = "$context.responseLength"
    })
  }
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_log_role.arn
  depends_on          = [aws_iam_role_policy_attachment.apigw_log_role_attach]
}


resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_alias.api_live.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}


resource "aws_sns_topic" "alarms" {
  name = var.sns_topic_name
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = var.log_group_api_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = var.log_group_worker_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "apigw_access" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-${var.api_gateway_name}"
  retention_in_days = var.api_gateway_log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "API Lambda errors"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
    Resource     = "${aws_lambda_function.api.function_name}:${aws_lambda_alias.api_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_duration_p95" {
  alarm_name          = "${var.project_name}-${var.environment}-api-duration-p95"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 10000
  alarm_description   = "API Lambda duration p95 >= 10s"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
    Resource     = "${aws_lambda_function.api.function_name}:${aws_lambda_alias.api_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-api-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "API Lambda throttles"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
    Resource     = "${aws_lambda_function.api.function_name}:${aws_lambda_alias.api_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-worker-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Worker Lambda errors"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.worker.function_name
    Resource     = "${aws_lambda_function.worker.function_name}:${aws_lambda_alias.worker_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "worker_duration_p95" {
  alarm_name          = "${var.project_name}-${var.environment}-worker-duration-p95"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 150000
  alarm_description   = "Worker Lambda duration p95 >= 150s"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.worker.function_name
    Resource     = "${aws_lambda_function.worker.function_name}:${aws_lambda_alias.worker_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "worker_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-worker-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Worker Lambda throttles"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.worker.function_name
    Resource     = "${aws_lambda_function.worker.function_name}:${aws_lambda_alias.worker_live.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-${var.environment}-dlq-messages"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "DLQ has messages"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = aws_sqs_queue.worker_dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  alarm_name          = "${var.project_name}-${var.environment}-queue-age"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 300
  alarm_description   = "Oldest message age >= 300s"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = aws_sqs_queue.worker_blue.name
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project_name}-${var.environment}-codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}

resource "aws_codedeploy_app" "api" {
  name             = "${var.project_name}-${var.environment}-api"
  compute_platform = "Lambda"
}

resource "aws_codedeploy_deployment_group" "api" {
  app_name              = aws_codedeploy_app.api.name
  deployment_group_name = "${var.project_name}-${var.environment}-api-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  deployment_config_name = "CodeDeployDefault.LambdaCanary10Percent10Minutes"

  alarm_configuration {
    enabled = true
    alarms = [
      aws_cloudwatch_metric_alarm.api_errors.alarm_name,
      aws_cloudwatch_metric_alarm.api_duration_p95.alarm_name,
      aws_cloudwatch_metric_alarm.api_throttles.alarm_name
    ]
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}
