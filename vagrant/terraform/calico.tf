
# https://docs.projectcalico.org/v3.7/manifests/calico.yaml
resource "null_resource" "calico" {

    provisioner "local-exec" {
        command = "kubectl --context=${var.k8s_cluster_context} apply -f https://docs.projectcalico.org/v3.7/manifests/calico.yaml"
    }
}
