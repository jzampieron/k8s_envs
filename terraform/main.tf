
data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}

#helm repo add rook-release https://charts.rook.io/release
data "helm_repository" "rook" {
    name = "rook-release"
    url  = "https://charts.rook.io/release"
}

# Name must be "kubernetes-dashboard" for the proxy to work
# Using: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:https/proxy/#!/login
# via 'kubectl proxy'
resource "helm_release" "dashboard" {
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

#helm install --namespace rook-ceph rook-release/rook-ceph
resource "helm_release" "rook-operator" {
    name       = "rook"
    namespace  = "persistence"
    repository = "${data.helm_repository.rook.metadata.0.name}"
    chart      = "rook-ceph"

    values = [ <<EOF
        resources:
            limits:
                cpu: 100m
                memory: 128Mi
            requests:
                cpu: 100m
                memory: 128Mi
EOF
    ]
}

resource "helm_release" "openebs" {
    count      = 0
    name       = "openebs"
    namespace  = "persistence"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "openebs"
    version    = "1.0.0" # app version 1.0.0

    set {
        # WTF --- don't send Google anything by default.
        name  = "analytics.enabled"
        value = "false"
    }
}

resource "helm_release" "prometheus" {
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