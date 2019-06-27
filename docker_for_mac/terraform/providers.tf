
provider "kubernetes" {
    host = "${var.k8s_api_url}"

    #client_certificate     = "${file("~/.kube/client-cert.pem")}"
    #client_key             = "${file("~/.kube/client-key.pem")}"
    #cluster_ca_certificate = "${file("~/.kube/cluster-ca-cert.pem")}"

    config_context_auth_info = "${var.k8s_cluster_root_user}"
    config_context_cluster   = "${var.k8s_cluster_context}"
}

provider "helm" {
    kubernetes {
        host = "${var.k8s_api_url}"
        #username = "ClusterMaster"
        #password = "MindTheGap"

        #client_certificate     = "${file("~/.kube/client-cert.pem")}"
        #client_key             = "${file("~/.kube/client-key.pem")}"
        #cluster_ca_certificate = "${file("~/.kube/cluster-ca-cert.pem")}"
        config_context = "${var.k8s_cluster_context}"
    }
}
