# Conflicts and Exceptions

This file tracks known conflicts between configuration, permissions, or docs, and how they were resolved.

## 2026-02-05
### IAM Permissions
- Issue: `AccessDenied` when creating S3, SQS, IAM, SNS, CloudWatch, CodeDeploy.
- Cause: AWS user lacked permissions.
- Resolution: Admin permissions granted; apply now permitted.

### Terraform Backend
- Issue: S3 backend init failed because bucket did not exist.
- Resolution: Added bootstrap Terraform to create state bucket + lock table, then reinitialized backend.

### CodeDeploy Lambda Configuration
- Issue: Invalid `load_balancer_info` and `deployment_group_blue_green_deployment_config` blocks for Lambda.
- Resolution: Removed those blocks.

### Alarm References
- Issue: Used `.name` instead of `.alarm_name` for CloudWatch alarms.
- Resolution: Updated to `.alarm_name`.

### API Gateway Integration URI
- Issue: Used alias ARN instead of `invoke_arn`.
- Resolution: Switched integration URI to `invoke_arn`.

## Status
No open conflicts.
