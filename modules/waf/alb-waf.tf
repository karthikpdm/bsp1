resource "aws_wafv2_web_acl" "portal_alb" {
  name        = "${var.project_name}-alb-portal-waf-${var.env}"
  description = "WAF Web ACL for Portal ALB"
  scope       = "REGIONAL"
 
  default_action {
    allow {}
  }
 
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "pw-waf-portal-cloudwatch-metric-${var.env}"
    sampled_requests_enabled   = true
  }
 
  rule {
    name     = "pw-waf-rule-${var.env}-region-block"
    priority = 0
 
    action {
      block {}
    }
 
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "pw-waf-portal-cloudwatch-metric-${var.env}-region-block"
      sampled_requests_enabled   = true
    }
 
    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["US", "IN"]
          }
        }
      }
    }
  }
 
  rule {
    name     = "enable-captcha"
    priority = 1
 
    action {
      allow {}
    }
 
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "pw-waf-portal-cloudwatch-metric-${var.env}-enable-captcha"
      sampled_requests_enabled   = true
    }
 
    statement {
      geo_match_statement {
        country_codes = ["US", "IN"]
      }
    }
 
 
  }
 
 
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2
 
    override_action {
      none {}
    }
 
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
 
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
 
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3
 
    override_action {
      none {}
    }
 
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
 
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }
 
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 4
 
    override_action {
      none {}
    }
 
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
 
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }
 
  rule {
    name     = "rate-limit-rule"
    priority = 5
 
    action {
      block {}
    }
 
    statement {
      rate_based_statement {
        limit                 = 1000
        aggregate_key_type    = "IP"
        evaluation_window_sec = 60
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "pw-waf-portal-cloudwatch-metric-${var.env}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
  name     = "AWSManagedRulesKnownBadInputsRuleSet"
  priority = 6

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
    sampled_requests_enabled   = true
  }
}

 
  tags = merge(
    { "Name"    = "${var.project_name}-alb-portal-waf-${var.env}" },
    var.map_tagging
  )
}

resource "aws_wafv2_web_acl_association" "waf-web-acl-association-internal" {
  resource_arn = data.aws_lb.internal-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.portal_alb.arn
}

resource "aws_wafv2_web_acl_association" "waf-web-acl-association-customer" {
  resource_arn = data.aws_lb.customer-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.portal_alb.arn
}

resource "aws_wafv2_web_acl_association" "waf-web-acl-association-website" {
  resource_arn = data.aws_lb.customer-website-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.portal_alb.arn
}
