#helm install --namespace rook-ceph rook-release/rook-ceph
resource "helm_release" "rook-operator" {
    name       = "rook"
    namespace  = "rook-ceph"
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
