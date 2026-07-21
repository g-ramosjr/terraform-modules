provider {
 version = "1.60.0"
}

module "vpc-presets" {
 source = "git::https://stash.aws.dnb.com/scm/ter/aws-net-sg.git?ref=v2.5.0"
 vpc_name = "${lookup(var.dbvars, "VpcName")}"
 subnets = "${lookup(var.dbvars, "SubnetNames")
}

