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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version. Must be in EKS standard support."
  type        = string
  default     = "1.37"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "node_min_size" {
  description = "Nodes that are always running"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Most nodes the Cluster Autoscaler can scale out to"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Starting node count. The Cluster Autoscaler manages it after creation."
  type        = number
  default     = 1
}