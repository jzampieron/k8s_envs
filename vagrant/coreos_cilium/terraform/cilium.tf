# This is a breakdown of the cilium-external-etcd.yaml file
# into terraform kubernetes provider compatible stuff.

resource "kubernetes_config_map" "cilium-config" {
  metadata {
    name      = "cilium-config"
    namespace = "kube-system"
  }

  data {
    # This etcd-config contains the etcd endpoints of your cluster. If you use
    # TLS please make sure you follow the tutorial in https://cilium.link/etcd-config
    etcd-config = <<EOF
      ---
      endpoints:
        - http://172.18.18.101:2379
        - http://172.18.18.102:2379
        - http://172.18.18.103:2379
      #
      # In case you want to use TLS in etcd, uncomment the 'ca-file' line
      # and create a kubernetes secret by following the tutorial in
      # https://cilium.link/etcd-config
      # ca-file: '/var/lib/etcd-secrets/etcd-client-ca.crt'
      #
      # In case you want client to server authentication, uncomment the following
      # lines and create a kubernetes secret by following the tutorial in
      # https://cilium.link/etcd-config
      # key-file: '/var/lib/etcd-secrets/etcd-client.key'
      # cert-file: '/var/lib/etcd-secrets/etcd-client.crt'
EOF
    # If you want to run cilium in debug mode change this value to true
    debug = "false"

    # If you want metrics enabled in all of your Cilium agents, set the port for
    # which the Cilium agents will have their metrics exposed.
    # This option deprecates the "prometheus-serve-addr" in the
    # "cilium-metrics-config" ConfigMap
    # NOTE that this will open the port on ALL nodes where Cilium pods are
    # scheduled.
    # prometheus-serve-addr: ":9090"

    # Enable IPv4 addressing. If enabled, all endpoints are allocated an IPv4
    # address.
    enable-ipv4 = "true"

    # Enable IPv6 addressing. If enabled, all endpoints are allocated an IPv6
    # address.
    enable-ipv6 = "true"

    # If a serious issue occurs during Cilium startup, this
    # invasive option may be set to true to remove all persistent
    # state. Endpoints will not be restored using knowledge from a
    # prior Cilium run, so they may receive new IP addresses upon
    # restart. This also triggers clean-cilium-bpf-state.
    clean-cilium-state = "false"

    # If you want to clean cilium BPF state, set this to true;
    # Removes all BPF maps from the filesystem. Upon restart,
    # endpoints are restored with the same IP addresses, however
    # any ongoing connections may be disrupted briefly.
    # Loadbalancing decisions will be reset, so any ongoing
    # connections via a service may be loadbalanced to a different
    # backend after restart.
    clean-cilium-bpf-state = "false"

    # Users who wish to specify their own custom CNI configuration file must set
    # custom-cni-conf to "true", otherwise Cilium may overwrite the configuration.
    custom-cni-conf = "false"

    # If you want cilium monitor to aggregate tracing for packets, set this level
    # to "low", "medium", or "maximum". The higher the level, the less packets
    # that will be seen in monitor output.
    monitor-aggregation = "none"

    # ct-global-max-entries-* specifies the maximum number of connections
    # supported across all endpoints, split by protocol: tcp or other. One pair
    # of maps uses these values for IPv4 connections, and another pair of maps
    # use these values for IPv6 connections.
    #
    # If these values are modified, then during the next Cilium startup the
    # tracking of ongoing connections may be disrupted. This may lead to brief
    # policy drops or a change in loadbalancing decisions for a connection.
    #
    # For users upgrading from Cilium 1.2 or earlier, to minimize disruption
    # during the upgrade process, comment out these options.
    bpf-ct-global-tcp-max = "524288"
    bpf-ct-global-any-max = "262144"

    # Pre-allocation of map entries allows per-packet latency to be reduced, at
    # the expense of up-front memory allocation for the entries in the maps. The
    # default value below will minimize memory usage in the default installation;
    # users who are sensitive to latency may consider setting this to "true".
    #
    # This option was introduced in Cilium 1.4. Cilium 1.3 and earlier ignore
    # this option and behave as though it is set to "true".
    #
    # If this value is modified, then during the next Cilium startup the restore
    # of existing endpoints and tracking of ongoing connections may be disrupted.
    # This may lead to policy drops or a change in loadbalancing decisions for a
    # connection for some time. Endpoints may need to be recreated to restore
    # connectivity.
    #
    # If this option is set to "false" during an upgrade from 1.3 or earlier to
    # 1.4 or later, then it may cause one-time disruptions during the upgrade.
    preallocate-bpf-maps = "false"

    # Regular expression matching compatible Istio sidecar istio-proxy
    # container image names
    sidecar-istio-proxy-image = "cilium/istio_proxy"

    # Encapsulation mode for communication between nodes
    # Possible values:
    #   - disabled
    #   - vxlan (default)
    #   - geneve
    tunnel = "vxlan"

    # Name of the cluster. Only relevant when building a mesh of clusters.
    cluster-name = "default"

    # Unique ID of the cluster. Must be unique across all conneted clusters and
    # in the range of 1 and 255. Only relevant when building a mesh of clusters.
    #cluster-id: 1

    # Interface to be used when running Cilium on top of a CNI plugin.
    # For flannel, use "cni0"
    flannel-master-device = ""

    # When running Cilium with policy enforcement enabled on top of a CNI plugin
    # the BPF programs will be installed on the network interface specified in
    # 'flannel-master-device' and on all network interfaces belonging to
    # a container. When the Cilium DaemonSet is removed, the BPF programs will
    # be kept in the interfaces unless this option is set to "true".
    flannel-uninstall-on-exit = "false"

    # Installs a BPF program to allow for policy enforcement in already running
    # containers managed by Flannel.
    # NOTE: This requires Cilium DaemonSet to be running in the hostPID.
    # To run in this mode in Kubernetes change the value of the hostPID from
    # false to true. Can be found under the path `spec.spec.hostPID`
    flannel-manage-existing-containers = "false"

    # DNS Polling periodically issues a DNS lookup for each `matchName` from
    # cilium-agent. The result is used to regenerate endpoint policy.
    # DNS lookups are repeated with an interval of 5 seconds, and are made for
    # A(IPv4) and AAAA(IPv6) addresses. Should a lookup fail, the most recent IP
    # data is used instead. An IP change will trigger a regeneration of the Cilium
    # policy for each endpoint and increment the per cilium-agent policy
    # repository revision.
    #
    # This option is disabled by default starting from version 1.4.x in favor
    # of a more powerful DNS proxy-based implementation, see [0] for details.
    # Enable this option if you want to use FQDN policies but do not want to use
    # the DNS proxy.
    #
    # To ease upgrade, users may opt to set this option to "true".
    # Otherwise please refer to the Upgrade Guide [1] which explains how to
    # prepare policy rules for upgrade.
    #
    # [0] http://docs.cilium.io/en/stable/policy/language/#dns-based
    # [1] http://docs.cilium.io/en/stable/install/upgrade/#changes-that-may-require-action
    tofqdns-enable-poller = "false"

    # wait-bpf-mount makes init container wait until bpf filesystem is mounted
    wait-bpf-mount = "false"

    # Enable legacy services (prior v1.5) to prevent from terminating existing
    # connections with services when upgrading Cilium from < v1.5 to v1.5.
    enable-legacy-services = "false"
  }
}

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

        #priorityClassName: system-node-critical
        restart_policy                   = "Always"
        service_account                  = "cilium"
        service_account_name             = "cilium"
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
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CILIUM_FLANNEL_UNINSTALL_ON_EXIT"
            value_from {
              config_map_key_ref {
                key      = "flannel-uninstall-on-exit"
                name     = "cilium-config"
                optional = true
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
                optional = true
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
                command = "/cni-install.sh"
              }
            }
            pre_stop {
              exec {
                command = "/cni-uninstall.sh"
              }
            }
          }

          liveness_probe {
            exec {
              command = "cilium status --brief"
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

          ports {
            containerPort = 9090
            hostPort      = 9090
            name          = "prometheus"
            protocol      = "TCP"
          }

          readiness_probe {
            exec {
              command = "cilium status --brief"
            }

            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 30
            success_threshold     = 1
            timeout_seconds       = 5
          }

          securityContext {
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

          dns_policy   = "ClusterFirstWithHostNet"
          host_network = true
          host_pid     = false

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
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CLEAN_CILIUM_BPF_STATE"
            value_from {
              config_map_key_ref {
                key      = "clean-cilium-bpf-state"
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CILIUM_WAIT_BPF_MOUNT"
            value_from {
              config_map_key_ref {
                key      = "wait-bpf-mount"
                name     = "cilium-config"
                optional = true
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
            type = "DirectoryOrCreate"
          }
        }

        # To keep state between restarts / upgrades for bpf maps
        volume {
          name = "bpf-maps"
          host_path {
            path = "/sys/fs/bpf"
            type = "DirectoryOrCreate"
          }
        }

        # To read docker events from the node
        volume {
          name = "docker-socket"
          host_path {
            path = "/var/run/docker.sock"
            type = "Socket"
          }
        }

        # To install cilium cni plugin in the host
        volume {
          name = "cni-path"
          host_path {
            path = "/opt/cni/bin"
            type = "DirectoryOrCreate"
          }
        }

        # To install cilium cni configuration in the host
        volume {
          name = "etc-cni-netd"
          host_path {
            path = "/etc/cni/net.d"
            type = "DirectoryOrCreate"
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
            name = "cilium-config"
            default_mode = 420
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
            default_mode = 420
            optional     = true
            secret_name  = "cilium-etcd-secrets"
          }
        }

        # To read the clustermesh configuration
        volume {
          name = "clustermesh-secrets"
          secret {
            default_mode = 420
            optional     = true
            secret_name  = "cilium-clustermesh"
          }
        }

        # To read the configuration from the config map
        volume {
          name = "cilium-config-path"
          configMap {
            name = "cilium-config"
          }
        }
      } # end init_container

    } # end spec

    update_strategy {
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
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_NAME"
            value_from {
              config_map_key_ref {
                key      = "cluster-name"
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CILIUM_CLUSTER_ID"
            value_from {
              config_map_key_ref {
                key      = "cluster-id"
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "CILIUM_DISABLE_ENDPOINT_CRD"
            value_from {
              config_map_key_ref {
                key      = "disable-endpoint-crd"
                name     = "cilium-config"
                optional = true
              }
            }
          }

          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                key      = "AWS_ACCESS_KEY_ID"
                name     = "cilium-aws"
                optional = true
              }
            }
          }

          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                key      = "AWS_SECRET_ACCESS_KEY"
                name     = "cilium-aws"
                optional = true
              }
            }
          }

          env {
            name = "AWS_DEFAULT_REGION"
            value_from {
              secret_key_ref {
                key      = "AWS_DEFAULT_REGION"
                name     = "cilium-aws"
                optional = true
              }
            }
          }

          livenessProbe {
            httpGet {
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
            readOnly  = true
          }
        } # end container

        dns_policy           = "ClusterFirst"
        priority_class_name  = "system-node-critical"
        restart_policy       = "Always"
        service_account      = "cilium-operator"
        service_account_name = "${kubernetes_service_account.cilium-operator.metadata.name}"

        # To read the etcd config stored in config maps
        volume {
          name = "etcd-config-path"
          configMap {
            name         = "${kubernetes_config_map.cilium-config.metadata.name}"
            default_mode = 420
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
            default_mode = 420
            optional     = true
            secretName   = "cilium-etcd-secrets"
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

