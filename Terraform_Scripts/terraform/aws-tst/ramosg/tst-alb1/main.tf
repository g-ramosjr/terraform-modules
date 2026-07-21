provider aws {
 version = "1.60.0"
}

module "vpc_presets" {
 source = "git::https://stash.aws.dnb.com/scm/ter/tf_vpc_presets.git?ref=v0.0.5"
 vpc_name = "${lookup(var.dbvars, "VpcName")}"
 subnets = "${lookup(var.dbvars,"SubnetNames")}"
  ami_name = "${lookup(var.dbvars,"AmiName" )}"
}


terraform {
 backend "s3" {}
}

module "security_group" {
 source = "git::https://stash.aws.dnb.com/scm/ter/aws-net-sg.git?ref=v2.5.0"
 name        = "${var.prefix}-tst-alb-${var.env}-001"
 description = "${var.prefix}-tst-alb-${var.env}-001"
 vpc_id      = "${module.vpc_presets.vpc_id}"


ingress_cidr_blocks = ["10.0.0.0/8","158.151.0.0/16"]
ingress_rules       = ["https-443-tcp"]

ingress_with_cidr_blocks = [
  {
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = "10.0.0.0/8,158.151.0.0/16"
  },
]
  egress_rules = ["all-all"]
  tags = "${var.tags}"

}




data "aws_acm_certificate" "cert"
    {
     domain = "${var.cert_name_prefix}"
    }

module "alb-tst" {
   source = "git::https://stash.aws.dnb.com/scm/ter/aws-alb.git?ref=v3.4.0"
   load_balancer_name  = "${var.prefix}-tst-alb-${var.env}"
   security_groups          = ["${module.security_group.this_security_group_id}"]
   logging_enabled          = false
   load_balancer_is_internal = true
#  logging_enabled          = true
#  log_bucket_name          = "${aws_s3_bucket.log_bucket.id}"
#  log_location_prefix      = "${var.log_location_prefix}"
   subnets                  = ["${module.vpc_presets.subnet_ids}"]
   tags                     = "${var.tags}"
   vpc_id                   = "${module.vpc_presets.vpc_id}"
   https_listeners          = "${local.https_listeners}"
   https_listeners_count    = "1"
   target_groups            = "${local.target_groups}"
   target_groups_count      = "1"

}

data "aws_route53_zone" "r53-zone-1" {
  name = "${var.dns_zone}"
}

resource "aws_route53_record" "route53" {
  zone_id            = "${data.aws_route53_zone.r53-zone-1.zone_id}"
  name               = "${var.alb_internal_dns}.${data.aws_route53_zone.r53-zone-1.name}"
  type               = "A"
  alias {
    name                   = "${module.alb-tst.dns_name}"
    zone_id                = "${module.alb-tst.load_balancer_zone_id}"
    evaluate_target_health = true
  }
}
