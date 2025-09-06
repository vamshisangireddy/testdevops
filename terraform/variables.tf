variable "aws_region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "us-west-1"
}

variable "aws_key_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
  default     = "jenkins-terraform"
}
