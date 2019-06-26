
variable "k8s_api_url" {
    type    = "string"
    default = "https://localhost:6443"
}

variable "k8s_cluster_context" {
    type    = "string"
    default = "docker-desktop"
}

variable "k8s_cluster_root_user" {
    type    = "string"
    default = "docker-for-desktop"
}

# Get via `kubectl describe secrets default`
variable "k8s_ui_secret_name" {
    type    = "string"
    default = "default-token-hxfzt"
}