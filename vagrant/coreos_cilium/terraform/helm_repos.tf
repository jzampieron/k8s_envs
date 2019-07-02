
data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}

#helm repo add rook-release https://charts.rook.io/release
data "helm_repository" "rook" {
    name = "rook-release"
    url  = "https://charts.rook.io/release"
}
