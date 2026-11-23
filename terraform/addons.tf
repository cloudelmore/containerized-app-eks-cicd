# Cluster add-ons
#   metrics-server               -> CPU/memory numbers for the HPA
#   Cluster Autoscaler           -> adds/removes nodes (1 to 4)
#   AWS Load Balancer Controller -> turns the app's Ingress into an ALB
#
# The autoscaler and LB controller call AWS APIs, so each gets its own
# IAM role through EKS Pod Identity (no access keys in the cluster).

# ------------------------------------------------------------- metrics-server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"

  depends_on = [module.eks]
}

# --------------------------------------------------------- Cluster Autoscaler
module "cluster_autoscaler_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.project_name}-cluster-autoscaler"

  # Built-in least-privilege policy: describe and resize only this cluster's node groups
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "cluster-autoscaler"
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.60.0"
  namespace  = "kube-system"

  values = [yamlencode({
    awsRegion = var.region

    # Finds the node group by the tags EKS puts on its Auto Scaling group:
    # k8s.io/cluster-autoscaler/enabled and k8s.io/cluster-autoscaler/<cluster name>
    autoDiscovery = {
      clusterName = module.eks.cluster_name
    }

    rbac = {
      serviceAccount = {
        name = "cluster-autoscaler" # must match the pod identity association
      }
    }

    extraArgs = {
      expander                    = "least-waste"
      balance-similar-node-groups = true
      # The app pods mount an emptyDir volume. Without this, the
      # autoscaler refuses to remove any node running an app pod.
      skip-nodes-with-local-storage = false
      # Scale down after 5 idle minutes instead of 10, to save money in a lab
      scale-down-unneeded-time   = "5m"
      scale-down-delay-after-add = "5m"
    }
  })]

  depends_on = [module.eks, time_sleep.wait_for_pod_identity]
}

# ------------------------------------------------ AWS Load Balancer Controller
module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.project_name}-aws-lb-controller"

  # Built-in policy: create and manage ALBs, target groups, and security groups
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# Pod Identity associations take a few seconds to start working after the
# API reports them as created. A pod created in that window never receives
# credentials, so wait before installing the charts that need them.
resource "time_sleep" "wait_for_pod_identity" {
  create_duration = "30s"

  depends_on = [
    module.cluster_autoscaler_pod_identity,
    module.lb_controller_pod_identity,
  ]
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.6.3"
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName  = module.eks.cluster_name
    region       = var.region
    vpcId        = module.vpc.vpc_id
    replicaCount = 1 # default is 2; one saves a pod slot on the small nodes

    serviceAccount = {
      name = "aws-load-balancer-controller" # must match the pod identity association
    }
  })]

  # Installed last. Its webhook checks Services as they're created, and if the
  # webhook isn't ready yet, other charts' Services fail to install.
  depends_on = [
    module.eks,
    time_sleep.wait_for_pod_identity,
    helm_release.metrics_server,
    helm_release.cluster_autoscaler,
  ]
}
