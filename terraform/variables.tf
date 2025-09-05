variable "aws_region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "aws_key_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
}