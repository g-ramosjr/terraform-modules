




variable "server_prefix"  { default = "aetstbobtl" } 
variable "server_suffix"  { default = "dnb.net"  } 
variable "instance_count" { default = "1"  } 
variable "availability_zones"  { default = [] } 

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

  name        = "tst-bob-001"
  description = "tst-bob-001"
  vpc_id      = "${module.vpc_presets.vpc_id}"

  ingress_cidr_blocks = ["10.0.0.0/8"]
  ingress_rules       = ["ssh-tcp", "http-80-tcp"]
  egress_rules        = ["all-all"]
  tags                = "${var.tags}"

}

module "ec2-1" {
  source = "git::https://stash.aws.dnb.com/scm/ter/aws-vm-os-lnx.git?ref=v1.0.0"

  instance_count              = "${var.instance_count}"

  server_prefix               = "${var.server_prefix}"
  server_suffix               = "${var.server_suffix}"
  ami                         = "${module.vpc_presets.ami_id}"
  instance_type               = "${var.instance_type}"
  subnet_ids                  = ["${module.vpc_presets.subnet_ids}"]

  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  partition_type              = "flat"
  key_name                    = "Enterprise_POC"
  join_idm                    = "true"
  enable_salt                 = "true"
  tags                        = "${var.tags}"
  volume_tags                 = "${merge(var.tags, map("Name", format("%s", "${var.server_prefix}")))}"
}

module "disk-1" {
  source = "../../../ter/testmodule/aws-vm-os-lnx-disk/"

  server_prefix      = "${var.server_prefix}"
  instance_ids       = ["${module.ec2-1.id}"]
  datadisk_size      = ["1024"]
  availability_zones = ["${module.ec2-1.availability_zone}"]
  force_detach       = "true"

  tags               = "${var.tags}"

}
