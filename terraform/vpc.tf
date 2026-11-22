# Ask AWS which AZs are available in this region, then use the first two
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  # cidrsubnet(base, newbits, netnum) carves a smaller block out of the VPC:
  #   public:  10.0.0.0/24,  10.0.1.0/24
  #   private: 10.0.10.0/24, 10.0.11.0/24
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  # One NAT gateway shared by both AZs keeps cost down.
  # Production would use one per AZ so losing an AZ doesn't cut off the other.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags the AWS Load Balancer Controller uses to find the right subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}