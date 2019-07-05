#
# The provide is missing *3* features
# type, priorityClassName and optional. 
#
resource "kubernetes_daemonset" "cilium" {
  count = 0
  metadata {
    labels = {
      "k8s-app"                       = "cilium"
      "kubernetes.io/cluster-service" = "true"
    }

    name      = "cilium"
    namespace = "kube-system"
  }

  spec { # end template
    selector {
      match_labels = {
        "k8s-app"                       = "cilium"
        "kubernetes.io/cluster-service" = "true"
      }
    }

    template {   # end spec
      metadata { # end template - metadata
        annotations = {
          "prometheus.io/port"   = "9090"
          "prometheus.io/scrape" = "true"
          # This annotation plus the CriticalAddonsOnly toleration makes
          # cilium to be a critical pod in the cluster, which ensures cilium
          # gets priority scheduling.
          # https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
          "scheduler.alpha.kubernetes.io/tolerations"  = <<EOF
            [{"key":"dedicated","operator":"Equal","value":"master","effect":"NoSchedule"}]
EOF

        }

        labels = {
          "k8s-app" = "cilium"
          "kubernetes.io/cluster-service" = "true"
        }
      }

      spec { # end init_container
        dns_policy = "ClusterFirstWithHostNet"
        host_network = true
        host_pid = false

        #priorityClassName: system-node-critical
        restart_policy = "Always"

        #service_account                  = "cilium"
        service_account_name = kubernetes_service_account.cilium.metadata[0].name
        termination_grace_period_seconds = 1

        #tolerations:
        #- operator: Exists

        container { # agent container
          args = [
            "--kvstore=etcd",
            "--kvstore-opt=etcd.config=/var/lib/etcd-config/etcd.config",
            "--config-dir=/tmp/cilium/config-map",
          ]

          command = ["cilium-agent"]

          env {
            name = "K8S_NODE_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "CILIUM_K8S_NAMESPACE"
            value_from {
              field_ref {
                api_version = "v1"
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "CILIUM_FLANNEL_MASTER_DEVICE"
            value_from {
              config_map_key_ref {
                key = "flannel-master-device"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_FLANNEL_UNINSTALL_ON_EXIT"
            value_from {
              config_map_key_ref {
                key = "flannel-uninstall-on-exit"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          # To be removed in Cilium 1.6, use prometheus-serve-addr in the
          # cilium-config ConfigMap
          env {
            name = "CILIUM_PROMETHEUS_SERVE_ADDR"
            value_from {
              config_map_key_ref {
                key = "prometheus-serve-addr"
                name = "cilium-metrics-config"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTERMESH_CONFIG"
            value = "/var/lib/cilium/clustermesh/"
          }

          image = "docker.io/cilium/cilium:v1.5.3"
          image_pull_policy = "IfNotPresent"

          lifecycle {
            post_start {
              exec {
                command = ["/cni-install.sh"]
              }
            }
            pre_stop {
              exec {
                command = ["/cni-uninstall.sh"]
              }
            }
          }

          liveness_probe {
            exec {
              command = ["cilium status --brief"]
            }
            failure_threshold = 10

            # The initial delay for the liveness probe is intentionally large to
            # avoid an endless kill & restart cycle if in the event that the initial
            # bootstrapping takes longer than expected.
            initial_delay_seconds = 120
            period_seconds = 30
            success_threshold = 1
            timeout_seconds = 5
          }

          name = "cilium-agent"

          port {
            container_port = 9090
            host_port = 9090
            name = "prometheus"
            protocol = "TCP"
          }

          readiness_probe {
            exec {
              command = ["cilium status --brief"]
            }

            failure_threshold = 3
            initial_delay_seconds = 5
            period_seconds = 30
            success_threshold = 1
            timeout_seconds = 5
          }

          security_context {
            capabilities {
              add = [
                "NET_ADMIN",
                "SYS_MODULE",
              ]
            }
            privileged = true
          }

          volume_mount {
            mount_path = "/sys/fs/bpf"
            name = "bpf-maps"
          }

          volume_mount {
            mount_path = "/var/run/cilium"
            name = "cilium-run"
          }

          volume_mount {
            mount_path = "/host/opt/cni/bin"
            name = "cni-path"
          }

          volume_mount {
            mount_path = "/host/etc/cni/net.d"
            name = "etc-cni-netd"
          }

          volume_mount {
            mount_path = "/var/run/docker.sock"
            name = "docker-socket"
            read_only = true
          }

          volume_mount {
            mount_path = "/var/lib/etcd-config"
            name = "etcd-config-path"
            read_only = true
          }

          volume_mount {
            mount_path = "/var/lib/etcd-secrets"
            name = "etcd-secrets"
            read_only = true
          }

          volume_mount {
            mount_path = "/var/lib/cilium/clustermesh"
            name = "clustermesh-secrets"
            read_only = true
          }

          volume_mount {
            mount_path = "/tmp/cilium/config-map"
            name = "cilium-config-path"
            read_only = true
          }

          # Needed to be able to load kernel modules
          volume_mount {
            mount_path = "/lib/modules"
            name = "lib-modules"
            read_only = true
          }
        }

        init_container { # end init_container
          name = "clean-cilium-state"
          image = "docker.io/cilium/cilium-init:2019-04-05"
          image_pull_policy = "IfNotPresent"
          command = ["/init-container.sh"]

          env {
            name = "CLEAN_CILIUM_STATE"
            value_from {
              config_map_key_ref {
                key = "clean-cilium-state"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CLEAN_CILIUM_BPF_STATE"
            value_from {
              config_map_key_ref {
                key = "clean-cilium-bpf-state"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_WAIT_BPF_MOUNT"
            value_from {
              config_map_key_ref {
                key = "wait-bpf-mount"
                name = kubernetes_config_map.cilium-config.metadata[0].name
                #optional = true
              }
            }
          }

          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }
            privileged = true
          }

          volume_mount {
            mount_path = "/sys/fs/bpf"
            name = "bpf-maps"
          }

          volume_mount {
            mount_path = "/var/run/cilium"
            name = "cilium-run"
          }
        }

        # To keep state between restarts / upgrades
        volume {
          name = "cilium-run"
          host_path {
            path = "/var/run/cilium"
            #type = "DirectoryOrCreate"
          }
        }

        # To keep state between restarts / upgrades for bpf maps
        volume {
          name = "bpf-maps"
          host_path {
            path = "/sys/fs/bpf"
            #type = "DirectoryOrCreate"
          }
        }

        # To read docker events from the node
        volume {
          name = "docker-socket"
          host_path {
            path = "/var/run/docker.sock"
            #type = "Socket"
          }
        }

        # To install cilium cni plugin in the host
        volume {
          name = "cni-path"
          host_path {
            path = "/opt/cni/bin"
            #type = "DirectoryOrCreate"
          }
        }

        # To install cilium cni configuration in the host
        volume {
          name = "etc-cni-netd"
          host_path {
            path = "/etc/cni/net.d"
            #type = "DirectoryOrCreate"
          }
        }

        # To be able to load kernel modules
        volume {
          name = "lib-modules"
          host_path {
            path = "/lib/modules"
          }
        }

        # To read the etcd config stored in config maps
        volume {
          name = "etcd-config-path"
          config_map {
            name = kubernetes_config_map.cilium-config.metadata[0].name
            default_mode = "0420"
            items {
              key = "etcd-config"
              path = "etcd.config"
            }
          }
        }

        # To read the k8s etcd secrets in case the user might want to use TLS
        volume {
          name = "etcd-secrets"
          secret {
            default_mode = "0420"

            #optional     = true
            secret_name = "cilium-etcd-secrets"
          }
        }

        # To read the clustermesh configuration
        volume {
          name = "clustermesh-secrets"
          secret {
            default_mode = "0420"

            #optional     = true
            secret_name = "cilium-clustermesh"
          }
        }

        # To read the configuration from the config map
        volume {
          name = "cilium-config-path"
          config_map {
            name = kubernetes_config_map.cilium-config.metadata[0].name
          }
        }
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        # Specifies the maximum number of Pods that can be unavailable during the update process.
        max_unavailable = 2
      }
    }
  }
}

