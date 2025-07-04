data "aws_kms_key" "sns" {
  key_id  = "alias/accelerator/kms/snstopic/key"
}

resource aws_sns_topic "monitoring-group" {
  name              = "${var.project_name}-eks-Monitoring-${var.env}"
  kms_master_key_id = data.aws_kms_key.sns.arn
}

resource "aws_sns_topic_subscription" "monitoring-test-subscription" {
  for_each = toset(var.email_subscribers)
  
  topic_arn                       = aws_sns_topic.monitoring-group.arn
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false

  protocol = "email"
  endpoint = each.value
}