
resource "helm_release" "coredns" {
    #depends_on = [ "null_resource.calico" ]
    depends_on = [ "null_resource.flannel" ]
    name       = "coredns"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "coredns"
    namespace  = "kube-system"
    version    = "1.5.3" # App version 1.5.0
}

# Name must be "kubernetes-dashboard" for the proxy to work
# Using: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:https/proxy/#!/login
# via 'kubectl proxy'
resource "helm_release" "dashboard" {
    depends_on = [ "helm_release.coredns" ]
    name       = "kubernetes-dashboard"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "kubernetes-dashboard"
    namespace  = "kube-system"
    version    = "1.5.2" # App version 1.10.1
}

# A root bearer token for accessing the dashboard.
data "kubernetes_secret" "root" {
    depends_on = [ "helm_release.dashboard" ]
    metadata {
        name      = "${var.k8s_ui_secret_name}"
        namespace = "default"
    }
}

output "token" {
    value = "${data.kubernetes_secret.root.data}"
}

# Then on: http://localhost:8001/api/v1/namespaces/monitoring/services/http:my-prometheus-server:80/proxy/graph
resource "helm_release" "prometheus" {
    depends_on = [ "helm_release.coredns" ]
    name       = "my-prometheus"
    namespace  = "monitoring"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "prometheus"
    version    = "8.11.4" # App version 2.9.2

#   values = [
#       "${file("values.yaml")}"
#   ]

    set {
        name  = "nodeExporter.enabled"
        value = "true"
    }

}