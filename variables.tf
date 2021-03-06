variable "vpc_id" {
  type        = string
  description = "Your VPC ID"
}

variable "base_ami_regexp" {
  default = "amzn2-ami-hvm-2.0.20190823.1-x86_64-ebs"
  type    = string
}

variable "instance_type" {
  default     = "t3.nano"
  description = "Type of instance to use"
}

variable "hostname" {
  default     = "proxy"
  description = "Hostname for the proxy machine"
}

variable "slack-hook" {
  default     = ""
  description = "Put a slack webhook here if you'd like a message when the proxy comes up..."
}

variable "ssh_authorized_keys" {
  description = "Default keys to put in authorized_keys"
  default     = ""
  type        = string
}

variable "cidr_block" {
  type        = string
  default     = "10.10.0.0/16"
  description = "Base IP address block you'd like your proxy to use for its AWS Security Group"
}

variable "cidr_block_offset" {
  type        = number
  default     = 255
  description = "What you'd like the 3rd octet of the IP CIDR block to be"
}

variable "tag_name" {
  description = "Default NAME tag resource in AWS"
  default     = "Squid Proxy"
}

variable "tags_extra" {
  description = "Extra tags you can use with AWS for resource tracking"
  default     = {}
  type        = map(string)
}

variable "proxy_username" {
  description = "Username to allow through squid"
  type        = string
  default     = "guest"
}

variable "proxy_password" {
  default = "guest"
  type    = string
}

variable "extra_security_groups" {
  type    = list(string)
  default = []
}