
# This is the POD CIDR, NOT the VM interface CIDR.
# And it is defined in the Vagrantfile.
variable "k8s_pod_cidr" {
    type    = "string"
    default = "10.200.0.0/16"
}

variable "k8s_api_url" {
    type    = "string"
    default = "https://10.240.0.20:6443"
}

variable "k8s_cluster_context" {
    type    = "string"
    default = "vagrant-darwin"
}

variable "k8s_cluster_root_user" {
    type    = "string"
    default = "admin-vagrant-darwin"
}
