variable "instance_name" {
  description = "Name of ec2 instance"
  type        = string
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-005fc0f236362e99f" # Ubuntu 20.04 LTS // us-east-1
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

variable "ZONE" {
  default = "us-east-1a"
}

variable "role" {
  description = "Name of the role to be attached to the EC2 instance upon creation"
}