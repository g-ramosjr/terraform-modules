variable "dbvars" {
  description = "Map of DB/environment-specific presets (VpcName, SubnetNames, AmiName, etc.)"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name for the security group"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = ""
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed for ingress (general rules and SNMP/ICMP overrides)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}