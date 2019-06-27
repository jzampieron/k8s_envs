# See: https://github.com/terra-farm/terraform-provider-virtualbox
resource "virtualbox_vm" "etcd" {
    count = 3
    name = "${format("node-%02d", count.index+1)}"

    image = ""
    cpus = 2
    memory = "512mib"

    network_adapter {
        type = "nat"
    }

    network_adapter {
        type = "bridged"
        host_interface = "en0"
    }

    optical_disks = ["./cloudinit.iso"]
}

output "IPAddr" {
    # Get the IPv4 address of the bridged adapter (the 2nd one) on 'node-02'
    value = "${element(virtualbox_vm.node.*.network_adapter.1.ipv4_address, 1)}"
}