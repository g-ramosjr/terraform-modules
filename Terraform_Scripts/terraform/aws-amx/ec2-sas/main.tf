provider "aws" {
  version = "1.60.0"
}

variable "server_prefix"  { default = "aeamxsassl" } 
variable "server_suffix"  { default = "vis1.dnb.net"  } 
variable "instance_count" { default = "1"  } 
variable "availability_zones"  { default = [] } 
variable dns_zone {}

module "vpc_presets" {
  source   = "git::https://stash.aws.dnb.com/scm/ter/tf_vpc_presets.git?ref=v0.0.5"
  vpc_name = "${lookup(var.dbvars, "VpcName")}"
  subnets  = "${lookup(var.dbvars, "SubnetNames")}"
  ami_name = "${lookup(var.dbvars, "AmiName")}"
}

terraform {
  backend "s3" {}
}

module "security_group" {
  source = "git::https://stash.aws.dnb.com/scm/ter/aws-net-sg.git?ref=v2.5.0"

  name        = "${var.name}"
  description = "${var.description}"
  vpc_id      = "${module.vpc_presets.vpc_id}"

  ingress_cidr_blocks = ["${var.ingress_cidr_blocks}"]
  ingress_rules       = ["ssh-tcp", "http-80-tcp", "https-443-tcp"]
  
  ingress_with_cidr_blocks = [
    {
      from_port   = 161
      to_port     = 161
      protocol    = "udp"
      description = "SNMP"
      cidr_blocks = "${var.ingress_cidr_blocks}"
    },
    {
      rule        = "all-icmp"
      cidr_blocks = "${var.ingress_cidr_blocks}"
    },
  ]
  
  egress_rules        = ["all-all"]
  tags                = "${var.tags}"

}

module "ec2-1" {
  source = "git::https://stash.aws.dnb.com/scm/ter/aws-vm-os-lnx.git?ref=v1.0.2"

  instance_count              = "${var.instance_count}"

  server_prefix               = "${var.server_prefix}"
  server_suffix               = "${var.server_suffix}"
  ami                         = "${module.vpc_presets.ami_id}"
  instance_type               = "${var.instance_type}"
  subnet_ids                  = ["${module.vpc_presets.subnet_ids}"]
  iam_instance_profile        = "${module.iam-1.iam_instance_profile_id}"
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  partition_type              = "flat"
  key_name                    = ""
  network_interface           = ""
  join_idm                    = "false"
  enable_salt                 = "false"
  tags                        = "${var.tags}"
  volume_tags                 = "${merge(var.tags, map("Name", format("%s", "${var.server_prefix}")))}"
}

module "iam-1" {
  source = "git::https://stash.aws.dnb.com/scm/ter/aws-iam-role.git//instance-default?ref=v1.0.0"

  server_prefix               = "${var.server_prefix}"
  tags                        = "${var.tags}"
}

module "disk-1" {
  source = "git::https://stash.aws.dnb.com/scm/ter/aws-vm-disk.git?ref=v1.0.0"
  
  instance_count     = "${var.instance_count}"
  server_prefix      = "${var.server_prefix}"
  instance_ids       = ["${module.ec2-1.id}"]
  datadisk_size      = ["50"]
  availability_zones = ["${module.ec2-1.availability_zone}"]
  force_detach       = "true"

  tags               = "${var.tags}"

}

data "aws_route53_zone" "r53-zone-1" {
  name = "${var.dns_zone}"
}
resource "aws_route53_record" "r53-record-1" {
  count              = "${var.instance_count}"
  zone_id            = "${data.aws_route53_zone.r53-zone-1.zone_id}"
  name               = "${var.server_prefix}${format("%02d",count.index+1)}.${var.server_suffix}"
  type               = "A"
  ttl                = "60"
  records            = ["${module.ec2-1.private_ip}"] 
}

output "Instance_IDs" {
  value       = ["${module.ec2-1.id}"]
}

output "Subnets" {
  value       = ["${module.vpc_presets.subnet_ids}"]
}

output "AZ" {
  value       = ["${module.ec2-1.availability_zone}"]
}


output "iam_id" {
  value        = ["${module.iam-1.iam_instance_profile_id}"]
}

output "iam_policy" {
  value        = ["${module.iam-1.iam_policy_policy}"]
}
