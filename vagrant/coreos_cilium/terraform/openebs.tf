
resource "helm_release" "openebs" {
    depends_on = [ "helm_release.coredns" ]
    name       = "openebs"
    namespace  = "openebs"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "openebs"
    version    = "1.0.0" # app version 1.0.0

    set {
        # WTF --- don't send Google anything by default.
        name  = "analytics.enabled"
        value = "false"
    }

    set {
        name  = "ndm.sparse.size"
        value = "1000000000"
    }

    # Not for production.
    set {
        name  = "jiva.replicas"
        value = "1"
    }
}

