variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"  
}

variable "public_key" {
  description = "The public key for the EC2 instance"
  type        = string
}
