# https://docs.projectcalico.org/v3.7/manifests/calico.yaml
data "template_file" "calico" {
    template = "${ file( "${path.cwd}/files/calico.yaml.tmpl" ) }"
    vars = {
        calico_ipv4pool_cidr = "${var.k8s_cidr}"
    }
}

resource "local_file" "calicocfg" {
    content  = "${data.template_file.calico.rendered}"
    filename = "${path.cwd}/outputs/calico.yaml"
}

resource "null_resource" "calico" {
    count = 0
    provisioner "local-exec" {
        command = "kubectl --context=${var.k8s_cluster_context} apply -f ${path.cwd}/outputs/calico.yaml"
    }
}

resource "null_resource" "flannel" {
    count = 1
    provisioner "local-exec" {
        command = "kubectl --context=${var.k8s_cluster_context} apply -f ${path.cwd}/files/kube-flannel.yaml"
    }
}