# Vagrant kubernetes cluster

A HA kubernetes cluster to be run with Vagrant.

## Setup
  * Create a new virtual network with ip range `10.240.0.0/24`.
    * For Windows, see [here](https://superuser.com/questions/339465/creating-a-virtual-nic-on-windows-7).
    * For Linux, see [here](https://www.linux.com/learn/intro-to-linux/2017/5/creating-virtual-machines-kvm-part-2-networking).
  * run `init.sh` to generate CA. (You need `docker`)
  * `vagrant up`.
  * if macOS
    * Run `mac.sh` to enable kubectl access to the cluster from your mac
  * Run `kubectl.sh` to setup a `kubectl` cluster info for the vagrant cluster.
  * Do a check: `kubectl --cluster=vagrant-darwin api-resources`
    * `vagrant-darwin` on macOS
    * `vagrant-linux` on Linux
  * Run the terraform code to deploy applications and core items.

# Networking

## intro

There are *3* networks at play:
* The VM network (10.240.x.y)
* The service network (10.32.x.y)
* The calico network for pods (10.200.x.y)

## Pod Network
To ping pods within pods running on different nodes, run below commands on the host machine:
  * *nix:
    - route add -net 10.200.1.0 netmask 255.255.255.0 gw 10.240.0.31
    - route add -net 10.200.2.0 netmask 255.255.255.0 gw 10.240.0.32
    - ...
  * Windows:
    - route add 10.200.1.0 mask 255.255.255.0 10.240.0.31 metric 325
    - route add 10.200.2.0 mask 255.255.255.0 10.240.0.32 metric 325
    - ...

## DNS Addon
  * Run the below command to start kube-dns:
    - `kubectl apply -f https://raw.githubusercontent.com/acedemand/kubernetes-cluster/master/deployments/kube-dns.yaml`
  * Run the below command to start flannel:
    - `kubectl apply -f https://raw.githubusercontent.com/acedemand/kubernetes-cluster/master/deployments/kube-flannel.yaml`

## Dashboard
Run the below command to start dashboard:
  * `kubectl apply -f https://raw.githubusercontent.com/acedemand/kubernetes-cluster/master/deployments/kubernetes-dashboard.yaml`
  * Run `kubectl -n kube-system edit service kubernetes-dashboard`
  * Change `type: ClusterIP` to `type: NodePort`
  * Run `kubectl -n kube-system get service kubernetes-dashboard` to get exposed service port.
  * Open your browser and go to `https://<node-ip>:<nodePort>`
