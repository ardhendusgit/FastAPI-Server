variable "instance_name" {
  description = "Name of ec2 instance"
  type        = string
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-005fc0f236362e99f" # Ubuntu 22.04 LTS // us-east-1
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

# variable "security_group_id" {
#   description = "ID of the corresponding security group"
#   type        = string
# }

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "certificate_arn" {
  description = "Amazon arn of issued certificate"
}

variable "ZONE" {
  default = "us-east-1a"
}

variable "instance_profile" {
  description = "Name of the instance profile to be attached to the EC2 instance upon creation"
}