




variable "server_prefix"  { default = "aetstapptw" } 
variable "server_suffix"  { default = "dnbint.net"  } 
variable "instance_count" { default = "2"  } 
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

  name        = "tst-rdp-001"
  description = "tst-rdp-001"
  vpc_id      = "${module.vpc_presets.vpc_id}"

  ingress_cidr_blocks = ["10.0.0.0/8"]
  ingress_rules       = ["rdp-tcp"]
  egress_rules        = ["all-all"]
  tags                = "${var.tags}"

}

module "ec2-1" {
#  source = "git::https://stash.aws.dnb.com/scm/ter/aws-vm-os-win.git?ref=v1.0.0"
  source = "../../../ter/aws-vm-os-win"

  instance_count              = "${var.instance_count}"

  server_prefix               = "${var.server_prefix}"
  server_suffix               = "${var.server_suffix}"
  ami                         = "${module.vpc_presets.ami_id}"
  instance_type               = "${var.instance_type}"
  subnet_ids                  = ["${module.vpc_presets.subnet_ids}"]
  iam_instance_profile        = ["${aws_iam_instance_profile.profile.*.id}"]

  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  dns_server1                 = "10.242.155.117"
  dns_server2                 = "10.242.157.78"
  key_name                    = "Enterprise_POC"
  tags                        = "${var.tags}"
  volume_tags                 = "${merge(var.tags, map("Name", format("%s", "${var.server_prefix}")))}"
}

#module "disk-1" {
##  source = "git::https://stash.aws.dnb.com/scm/ter/aws-vm-disk.git?ref=v1.0.0"
#  source = "../../../ter/aws-vm-disk"
#
#  instance_count              = "${var.instance_count}"
#
#  server_prefix      = "${var.server_prefix}"
#  instance_ids       = ["${module.ec2-1.id}"]
#  datadisk_size      = ["50"]
#  availability_zones = ["${module.ec2-1.availability_zone}"]
#  force_detach       = "true"
#
#  tags               = "${var.tags}"
#
#}

# IAM Policy
resource "aws_iam_policy" "policy" {
  count = "${var.instance_count}"
  name = "${var.server_prefix}-policy${format("%02d",count.index+1)}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeTags"
            ],
            "Effect": "Allow",
            "Resource": "${element(module.ec2-1.arn, count.index)}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "role" {
    count = "${var.instance_count}"
    name = "${var.server_prefix}-role${format("%02d",count.index+1)}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy" {
  count = "${var.instance_count}"
  role       = "${element(aws_iam_role.role.*.name, count.index)}"
  policy_arn = "${element(aws_iam_policy.policy.*.arn, count.index)}"
}

resource "aws_iam_instance_profile" "profile" {
    count = "${var.instance_count}"
    name  = "${var.server_prefix}-profile${format("%02d",count.index+1)}"
    role  = "${element(aws_iam_role.role.*.name, count.index)}"
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
