# persistence.storageClass

resource "helm_release" "postgres" {
    depends_on = [ "helm_release.openebs" ]
    name       = "postgres"
    namespace  = "apps"
    repository = "${data.helm_repository.stable.metadata.0.name}"
    chart      = "postgresql"
    version    = "5.3.10" # app version 11.4.0

    set {
        name  = "persistence.storageClass"
        value = "openebs-hostpath"
    }

    set {
        name  = "persistence.size"
        value = "500M"
    }
}