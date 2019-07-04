# This is a breakdown of the cilium-external-etcd.yaml file
# into terraform kubernetes provider compatible stuff.

resource "kubernetes_service_account" "cilium-operator" {
  metadata {
    name      = "cilium-operator"
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account" "cilium" {
  metadata {
    name      = "cilium"
    namespace = "kube-system"
  }
}

# daemonset.apps/cilium created
resource "kubernetes_daemonset" "cilium" {

  metadata {

    labels {
      "k8s-app"                       = "cilium"
      "kubernetes.io/cluster-service" = "true"
    }

    name      = "cilium"
    namespace = "kube-system"

  }

  spec {

    selector {

      match_labels {
        "k8s-app"                       = "cilium"
        "kubernetes.io/cluster-service" = "true"
      }

    }

    template {

      metadata {

        annotations {
          "prometheus.io/port"   = "9090"
          "prometheus.io/scrape" = "true"
          # This annotation plus the CriticalAddonsOnly toleration makes
          # cilium to be a critical pod in the cluster, which ensures cilium
          # gets priority scheduling.
          # https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
          "scheduler.alpha.kubernetes.io/tolerations"  = <<EOF
            '[{"key":"dedicated","operator":"Equal","value":"master","effect":"NoSchedule"}]'
EOF
        }

        labels {
          "k8s-app"                       = "cilium"
          "kubernetes.io/cluster-service" = "true"
        }

      } # end template - metadata

      spec {

        dns_policy   = "ClusterFirstWithHostNet"
        host_network = true
        host_pid     = false

        #priorityClassName: system-node-critical
        restart_policy                   = "Always"
        #service_account                  = "cilium"
        service_account_name             = "${kubernetes_service_account.cilium.metadata.name}"
        termination_grace_period_seconds = 1
        #tolerations:
        #- operator: Exists

        container {

          args = [
            "--kvstore=etcd",
            "--kvstore-opt=etcd.config=/var/lib/etcd-config/etcd.config",
            "--config-dir=/tmp/cilium/config-map"
          ]

          command = [ "cilium-agent" ]

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
            name = "CILIUM_K8S_NAMESPACE"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.namespace"
              }
            }
          }

          env {
            name = "CILIUM_FLANNEL_MASTER_DEVICE"
            value_from {
              config_map_key_ref {
                key      = "flannel-master-device"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_FLANNEL_UNINSTALL_ON_EXIT"
            value_from {
              config_map_key_ref {
                key      = "flannel-uninstall-on-exit"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
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
                key      = "prometheus-serve-addr"
                name     = "cilium-metrics-config"
                #optional = true
              }
            }
          }

          env {
            name  = "CILIUM_CLUSTERMESH_CONFIG"
            value = "/var/lib/cilium/clustermesh/"
          }

          image             = "docker.io/cilium/cilium:v1.5.3"
          image_pull_policy = "IfNotPresent"

          lifecycle {
            post_start {
              exec {
                command = [ "/cni-install.sh" ]
              }
            }
            pre_stop {
              exec {
                command = [ "/cni-uninstall.sh" ]
              }
            }
          }

          liveness_probe {
            exec {
              command = [ "cilium status --brief" ]
            }
            failure_threshold = 10
            # The initial delay for the liveness probe is intentionally large to
            # avoid an endless kill & restart cycle if in the event that the initial
            # bootstrapping takes longer than expected.
            initial_delay_seconds = 120
            period_seconds        = 30
            success_threshold     = 1
            timeout_seconds       = 5
          }

          name = "cilium-agent"

          port {
            container_port = 9090
            host_port      = 9090
            name           = "prometheus"
            protocol       = "TCP"
          }

          readiness_probe {
            exec {
              command = [ "cilium status --brief" ]
            }

            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 30
            success_threshold     = 1
            timeout_seconds       = 5
          }

          security_context {
            capabilities {
              add = [
                "NET_ADMIN",
                "SYS_MODULE"
              ]
            }
            privileged = true
          }

          volume_mount {
            mount_path = "/sys/fs/bpf"
            name       = "bpf-maps"
          }

          volume_mount {
            mount_path = "/var/run/cilium"
            name       = "cilium-run"
          }

          volume_mount {
            mount_path = "/host/opt/cni/bin"
            name       = "cni-path"
          }

          volume_mount {
            mount_path = "/host/etc/cni/net.d"
            name       = "etc-cni-netd"
          }

          volume_mount {
            mount_path = "/var/run/docker.sock"
            name       = "docker-socket"
            read_only  = true
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

          volume_mount {
            mount_path = "/var/lib/cilium/clustermesh"
            name       = "clustermesh-secrets"
            read_only  = true
          }

          volume_mount {
            mount_path = "/tmp/cilium/config-map"
            name       = "cilium-config-path"
            read_only  = true
          }

          # Needed to be able to load kernel modules
          volume_mount {
            mount_path = "/lib/modules"
            name       = "lib-modules"
            read_only  = true
          }

        } # agent container

        init_container {

          name              = "clean-cilium-state"
          image             = "docker.io/cilium/cilium-init:2019-04-05"
          image_pull_policy = "IfNotPresent"
          command           = [ "/init-container.sh" ]

          env {
            name = "CLEAN_CILIUM_STATE"
            value_from {
              config_map_key_ref {
                key      = "clean-cilium-state"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CLEAN_CILIUM_BPF_STATE"
            value_from {
              config_map_key_ref {
                key      = "clean-cilium-bpf-state"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_WAIT_BPF_MOUNT"
            value_from {
              config_map_key_ref {
                key      = "wait-bpf-mount"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          security_context {
            capabilities {
              add = [ "NET_ADMIN" ]
            }
            privileged = true
          }

          volume_mount {
            mount_path = "/sys/fs/bpf"
            name       = "bpf-maps"
          }

          volume_mount {
            mount_path = "/var/run/cilium"
            name       = "cilium-run"
          }

        } # end init_container

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
            name = "${kubernetes_config_map.cilium-config.metadata.name}"
            default_mode = "0420"
            items {
              key  = "etcd-config"
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
            secret_name  = "cilium-etcd-secrets"
          }
        }

        # To read the clustermesh configuration
        volume {
          name = "clustermesh-secrets"
          secret {
            default_mode = "0420"
            #optional     = true
            secret_name  = "cilium-clustermesh"
          }
        }

        # To read the configuration from the config map
        volume {
          name = "cilium-config-path"
          config_map {
            name = "${kubernetes_config_map.cilium-config.metadata.name}"
          }
        }
      } # end init_container

    } # end spec

    strategy {
      type = "RollingUpdate"
      rolling_update {
        # Specifies the maximum number of Pods that can be unavailable during the update process.
        max_unavailable = 2
      }
    }

  } # end template

}

resource "kubernetes_deployment" "cilium-operator" {

  metadata {
    labels {
      "io.cilium/app" = "operator"
      name            = "cilium-operator"
    }
    name      = "cilium-operator"
    namespace = "kube-system"
  }

  spec {

    replicas = 1

    selector {
      match_labels {
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
        labels {
          "io.cilium/app" = "operator"
          name            = "cilium-operator"
        }
      }

      spec {

        container {
          image             = "docker.io/cilium/operator:v1.5.3"
          image_pull_policy = "IfNotPresent"
          name              = "cilium-operator"

          args = [
            "--debug=$(CILIUM_DEBUG)",
            "--kvstore=etcd",
            "--kvstore-opt=etcd.config=/var/lib/etcd-config/etcd.config"
          ]

          command = [ "cilium-operator"]

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
                key      = "debug"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_NAME"
            value_from {
              config_map_key_ref {
                key      = "cluster-name"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_ID"
            value_from {
              config_map_key_ref {
                key      = "cluster-id"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "CILIUM_DISABLE_ENDPOINT_CRD"
            value_from {
              config_map_key_ref {
                key      = "disable-endpoint-crd"
                name     = "${kubernetes_config_map.cilium-config.metadata.name}"
                #optional = true
              }
            }
          }

          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                key      = "AWS_ACCESS_KEY_ID"
                name     = "cilium-aws"
                #optional = true
              }
            }
          }

          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                key      = "AWS_SECRET_ACCESS_KEY"
                name     = "cilium-aws"
                #optional = true
              }
            }
          }

          env {
            name = "AWS_DEFAULT_REGION"
            value_from {
              secret_key_ref {
                key      = "AWS_DEFAULT_REGION"
                name     = "cilium-aws"
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
            name      = "etcd-secrets"
            read_only = true
          }
        } # end container

        dns_policy           = "ClusterFirst"
        #priority_class_name  = "system-node-critical"
        restart_policy       = "Always"
        #service_account      = "cilium-operator"
        service_account_name = "${kubernetes_service_account.cilium-operator.metadata.name}"

        # To read the etcd config stored in config maps
        volume {
          name = "etcd-config-path"
          config_map {
            name         = "${kubernetes_config_map.cilium-config.metadata.name}"
            default_mode = "0420"
            items {
              key  = "etcd-config"
              path = "etcd.config"
            }
          }
        } # end volume

        # To read the k8s etcd secrets in case the user might want to use TLS
        volume {
          name = "etcd-secrets"
          secret {
            default_mode = "0420"
            #optional     = true
            secret_name  = "cilium-etcd-secrets"
          }
        } # end volume

      }
    }
  }
}

resource "kubernetes_cluster_role" "cilium-operator" {

  metadata {
    name = "cilium-operator"
  }

  rule {
    api_groups = [ "" ]
    # to get k8s version and status
    resources = [ "componentstatuses" ]
    verbs = [ "get" ]
  }

  rule {
    api_groups = [ "" ]
    # to automatically delete [core|kube]dns pods so that are starting to being
    # managed by Cilium
    verbs = [ "get", "list", "watch", "delete" ]
  }

  rule {
    api_groups = [ "" ]
    # to automatically read from k8s and import the node's pod CIDR to cilium's
    # etcd so all nodes know how to reach another pod running in in a different
    # node.
    # to perform the translation of a CNP that contains `ToGroup` to its endpoints
    resources = [ "nodes", "services", "endpoints" ]
    verbs = [ "get", "list", "watch" ]
  }

  rule {
    api_groups = [ "cilium.io" ]
    resources = [
      "ciliumnetworkpolicies",
      "ciliumnetworkpolicies/status",
      "ciliumendpoints",
      "ciliumendpoints/status"
    ]
    verbs = [ "'*'" ]
  }

}

resource "kubernetes_cluster_role" "cilium" {

  metadata {
    name = "cilium"
  }

  rule {
    api_groups = [ "networking.k8s.io" ]
    resources = [ "networkpolicies" ]
    verbs     = [ "get", "list", "watch" ]
  }

  rule {
    api_groups = [ "" ]
    resources = [
      "namespaces",
      "services",
      "nodes",
      "endpoints",
      "componentstatuses"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = [ "" ]
    resources = [
      "pods",
      "nodes"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "update"
    ]
  }

  rule {
    api_groups = [ "" ]
    resources = [
      "nodes",
      "nodes/status"
    ]
    verbs = [
      "patch"
    ]
  }

  rule {
    api_groups = [ "extensions" ]
    resources = [ "ingresses" ]
    verbs = [
      "create",
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = [ "apiextensions.k8s.io" ]
    resources = [ "customresourcedefinitions" ]
    verbs = [
      "create",
      "get",
      "list",
      "watch",
      "update"
    ]
  }

  rule {
    api_groups = [ "cilium.io" ]
    resources = [
      "ciliumnetworkpolicies",
      "ciliumnetworkpolicies/status",
      "ciliumendpoints",
      "ciliumendpoints/status"
    ]
    verbs = [ "'*'" ]
  }

}

resource "kubernetes_cluster_role_binding" "cilium-operator" {

  metadata {
    name = "cilium-operator"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cilium-operator"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cilium-operator"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "cilium" {

  metadata {
    name = "cilium"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cilium"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cilium"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:nodes"
    api_group = "rbac.authorization.k8s.io"
  }

}

