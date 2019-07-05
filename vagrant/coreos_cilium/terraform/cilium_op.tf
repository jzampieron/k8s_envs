#
# This will not work until the provider is updated.
# it is missing a couple features, e.g. optional and priority_class_name
#
resource "kubernetes_deployment" "cilium-operator" {
  count = 0
  metadata {
    labels = {
      "io.cilium/app" = "operator"
      name            = "cilium-operator"
    }
    name      = "cilium-operator"
    namespace = "kube-system"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "io.cilium/app" = "operator"
        name            = "cilium-operator"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 1
      }
    }

    template {
      metadata {
        labels = {
          "io.cilium/app" = "operator"
          name            = "cilium-operator"
        }
      }

      spec {
        container { # end container
          image             = "docker.io/cilium/operator:v1.5.3"
          image_pull_policy = "IfNotPresent"
          name              = "cilium-operator"

          args = [
            "--debug=$(CILIUM_DEBUG)",
            "--kvstore=etcd",
            "--kvstore-opt=etcd.config=/var/lib/etcd-config/etcd.config",
          ]

          command = ["cilium-operator"]

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.namespace"
              }
            }
          }

          env {
            name = "K8S_NODE_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "spec.nodeName"
              }
            }
          }

          env {
            name = "CILIUM_DEBUG"
            value_from {
              config_map_key_ref {
                key  = "debug"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_NAME"
            value_from {
              config_map_key_ref {
                key  = "cluster-name"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_ID"
            value_from {
              config_map_key_ref {
                key  = "cluster-id"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_DISABLE_ENDPOINT_CRD"
            value_from {
              config_map_key_ref {
                key  = "disable-endpoint-crd"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                key  = "AWS_ACCESS_KEY_ID"
                name = "cilium-aws"
                #optional = true
              }
            }
          }

          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                key  = "AWS_SECRET_ACCESS_KEY"
                name = "cilium-aws"
                #optional = true
              }
            }
          }

          env {
            name = "AWS_DEFAULT_REGION"
            value_from {
              secret_key_ref {
                key  = "AWS_DEFAULT_REGION"
                name = "cilium-aws"
                #optional = true
              }
            }
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = 9234
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 3
          }

          volume_mount {
            mount_path = "/var/lib/etcd-config"
            name       = "etcd-config-path"
            read_only  = true
          }

          volume_mount {
            mount_path = "/var/lib/etcd-secrets"
            name       = "etcd-secrets"
            read_only  = true
          }
        }

        dns_policy = "ClusterFirst"

        #priority_class_name  = "system-node-critical"
        restart_policy = "Always"

        #service_account      = "cilium-operator"
        service_account_name = kubernetes_service_account.cilium-operator.metadata[0].name

        # To read the etcd config stored in config maps
        volume { # end volume
          name = "etcd-config-path"
          config_map {
            name         = kubernetes_config_map.cilium-config.metadata[0].name
            default_mode = "0420"
            items {
              key  = "etcd-config"
              path = "etcd.config"
            }
          }
        }

        # To read the k8s etcd secrets in case the user might want to use TLS
        volume { # end volume
          name = "etcd-secrets"
          secret {
            default_mode = "0420"

            #optional     = true
            secret_name = "cilium-etcd-secrets"
          }
        }
      }
    }
  }
}

