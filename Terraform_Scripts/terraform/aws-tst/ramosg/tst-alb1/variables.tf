variable "prefix" {}
variable "env" {}
variable "cert_name_prefix" {}

variable "availability_zones"  { default = [] }
variable "dns_zone" {}
variable "alb_internal_dns" {}

variable "dbvars" {
  type = "map"
}

variable "tags" {
  type = "map"
}
