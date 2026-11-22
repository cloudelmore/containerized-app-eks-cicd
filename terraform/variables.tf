variable "region" {
  description = "AWS region for every resource"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for the VPC, cluster, ECR repository, and Jenkins server"
  type        = string
  default     = "hello-world"
}