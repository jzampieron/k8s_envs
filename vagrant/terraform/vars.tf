
variable "k8s_cidr" {
    type    = "string"
    default = "10.240.0.0/16"
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

# Get via `kubectl describe secrets default`
variable "k8s_ui_secret_name" {
    type    = "string"
    default = "default-token-clkjb"
}