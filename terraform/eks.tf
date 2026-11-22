module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-eks"
  kubernetes_version = var.cluster_version

  # Control plane network interfaces and worker nodes go in the private subnets
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Lets kubectl and helm reach the API server from your PC (and later Jenkins).
  # Authentication is still required; this only makes the endpoint reachable.
  endpoint_public_access = true

  # Whoever runs `terraform apply` (your IAM user) becomes cluster admin
  enable_cluster_creator_admin_permissions = true

  # EKS-managed add-ons: AWS installs and updates these
  addons = {
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        role = "app"
      }
    }
  }
}