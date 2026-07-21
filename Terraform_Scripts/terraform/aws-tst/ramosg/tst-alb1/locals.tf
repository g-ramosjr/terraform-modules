locals {
  https_listeners = "${list(
                         map("certificate_arn", "${data.aws_acm_certificate.cert.arn}",
                           "port",443,
                           "ssl_policy", "ELBSecurityPolicy-TLS-1-2-2017-01",
                           "target_group_index", 0
                          )
                         )}"

  target_groups = "${list(
                      map("name", "${var.prefix}-tstapp8080-${var.env}",
                      "backend_protocol", "HTTP",
                      "backend_port", 8080,
                      "slow_start", 100,
                      "health_check_internal", 30,
                      "health_check_port", 8080,
                      "health_check_path", "/health",
                      "health_check_healthy_threshold", 3,
                      "health_check_unhealthy_threshold", 2,
                      "health_check_timeout", 10,
                      "health_check_matcher", 200
                      ))}"
}