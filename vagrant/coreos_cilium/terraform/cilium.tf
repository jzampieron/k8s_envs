# This is a breakdown of the cilium-external-etcd.yaml file
# into terraform kubernetes provider compatible stuff.

resource "null_resource" "cilium-pods" {
    count = 1
    depends_on = [
      "kubernetes_cluster_role_binding.cilium",
      "kubernetes_cluster_role_binding.cilium-operator",
      "kubernetes_config_map.cilium-config"
    ]
    provisioner "local-exec" {
        command = "kubectl --context=${var.k8s_cluster_context} apply -f ${path.cwd}/files/cilium-base.yaml"
    }
}

resource "kubernetes_service_account" "cilium-operator" {
  metadata {
    name      = "cilium-operator"
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account" "cilium" {
  metadata {
    name      = "cilium"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "cilium-operator" {
  metadata {
    name = "cilium-operator"
  }

  rule {
    api_groups = [""]

    # to get k8s version and status
    resources = ["componentstatuses"]
    verbs     = ["get"]
  }

  rule {
    api_groups = [""]

    # to automatically delete [core|kube]dns pods so that are starting to being
    # managed by Cilium
    resources = ["pods"]
    verbs     = ["get", "list", "watch", "delete"]
  }

  rule {
    api_groups = [""]

    # to automatically read from k8s and import the node's pod CIDR to cilium's
    # etcd so all nodes know how to reach another pod running in in a different
    # node.
    # to perform the translation of a CNP that contains `ToGroup` to its endpoints
    resources = ["nodes", "services", "endpoints"]
    verbs     = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["cilium.io"]
    resources = [
      "ciliumnetworkpolicies",
      "ciliumnetworkpolicies/status",
      "ciliumendpoints",
      "ciliumendpoints/status",
    ]
    verbs = ["'*'"]
  }
}

resource "kubernetes_cluster_role" "cilium" {
  metadata {
    name = "cilium"
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "services", "nodes", "endpoints", "componentstatuses"]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes"]
    verbs = [
      "get",
      "list",
      "watch",
      "update",
    ]
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "nodes/status",
    ]
    verbs = [
      "patch",
    ]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs = [
      "create",
      "get",
      "list",
      "watch",
    ]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs = [
      "create",
      "get",
      "list",
      "watch",
      "update",
    ]
  }

  rule {
    api_groups = ["cilium.io"]
    resources = [
      "ciliumnetworkpolicies",
      "ciliumnetworkpolicies/status",
      "ciliumendpoints",
      "ciliumendpoints/status",
    ]
    verbs = ["'*'"]
  }
}

resource "kubernetes_cluster_role_binding" "cilium-operator" {
  metadata {
    name = "cilium-operator"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.cilium-operator.metadata.0.name}"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.cilium-operator.metadata.0.name}"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "cilium" {
  metadata {
    name = "cilium"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.cilium.metadata.0.name}"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.cilium.metadata.0.name}"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:nodes"
    api_group = "rbac.authorization.k8s.io"
  }
}

