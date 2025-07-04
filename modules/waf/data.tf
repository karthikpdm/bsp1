data "aws_lb" "customer-alb" {
  name = "${var.project_name}-alb-customer-${var.env}"
}

data "aws_lb" "internal-alb" {
  name = "${var.project_name}-alb-internal-${var.env}"
}

data "aws_lb" "customer-website-alb" {
  name = "${var.project_name}-alb-website-${var.env}"
}