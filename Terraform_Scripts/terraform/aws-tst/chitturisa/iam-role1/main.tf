
variable "server_prefix"  { default = "aetstlnxtl" } 
#variable "role_count"     { default = "2" } 

terraform {
  backend "s3" {}
}

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
