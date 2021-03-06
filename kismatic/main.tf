provider "opc" {
  user = "${var.user}"
  password = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint = "${var.endpoint}"
}

resource "opc_compute_ssh_key" "default" {
  name = "kismatic-cluster-ssh"
  key = "${file(var.ssh_public_key)}"
  enabled = true
}

# Create the bootstrap node
resource "opc_compute_instance" "bootstrap_node" {
  image_list = "${var.image}"
  name = "bootstrap-node"
  label= "bootstrap-node"
  hostname = "bootstrap.compute-${var.domain}.oraclecloud.internal."
  shape = "oc3"
  ssh_keys = [ "${opc_compute_ssh_key.default.id}" ]
  networking_info {
    index = 1
    shared_network = true
    nat = [ "${opc_compute_ip_reservation.bootstrap_node_ip_reservation.name}" ]
  }
}

# Create the Kubernetes Master Nodes (e.g. master1)
resource "opc_compute_instance" "master_nodes" {
  count = "${var.master_count}"
  image_list = "${var.image}"
  name = "${format("master%1d", count.index + 1)}"
  label = "${format("master%1d", count.index + 1)}"
  hostname = "${format("master%1d", count.index + 1)}.compute-${var.domain}.oraclecloud.internal."
  shape = "oc3"
  ssh_keys = [ "${opc_compute_ssh_key.default.id}" ]
}

# Create the Kubernetes Etcd Nodes (e.g. etcd1)
resource "opc_compute_instance" "etcd_nodes" {
  count  = "${var.etcd_count}"
  image_list = "${var.image}"
  name = "${format("etcd%1d", count.index + 1)}"
  label = "${format("etcd%1d", count.index + 1)}"
  hostname = "${format("etcd%1d", count.index + 1)}.compute-${var.domain}.oraclecloud.internal."
  shape = "oc3"
  ssh_keys = [ "${opc_compute_ssh_key.default.id}" ]
}

# Create the Kubernetes worker Nodes (e.g. worker1)
resource "opc_compute_instance" "worker_nodes" {
  count = "${var.worker_count}"
  image_list = "${var.image}"
  name = "${format("worker%1d", count.index + 1)}"
  label = "${format("worker%1d", count.index + 1)}"
  hostname = "${format("worker%1d", count.index + 1)}.compute-${var.domain}.oraclecloud.internal."
  shape = "oc3"
  ssh_keys = [ "${opc_compute_ssh_key.default.id}" ]
}

# Public IP Reservations
resource "opc_compute_ip_reservation" "bootstrap_node_ip_reservation" {
  name = "kismatic-bootstrap-node"
  parent_pool = "/oracle/public/ippool"
  permanent = true
}

resource "opc_compute_ip_reservation" "master_node_reservations" {
  count = "${var.master_count}"
  name = "kubenetes-master"
  parent_pool = "/oracle/public/ippool"
  permanent = true
  tags = [ "${var.cluster_tag}" ]
}

resource "opc_compute_ip_reservation" "etcd_node_reservations" {
  count = "${var.etcd_count}"
  name = "kubenetes-etcd"
  parent_pool = "/oracle/public/ippool"
  permanent = true
  tags = [ "${var.cluster_tag}" ]
}

resource "opc_compute_ip_reservation" "worker_node_reservations" {
  count = "${var.worker_count}"
  name =  "kubenetes-worker"
  parent_pool = "/oracle/public/ippool"
  permanent = true
  tags = [ "${var.cluster_tag}" ]
}

resource "opc_compute_ip_association" "master_node_ip_associations" {
  count = "${var.master_count}"
  vcable = "${element(opc_compute_instance.master_nodes.*.vcable, count.index)}"
  parent_pool = "ipreservation:${element(opc_compute_ip_reservation.master_node_reservations.*.name, count.index)}"
}

resource "opc_compute_ip_association" "etcd_node_ip_associations" {
  count = "${var.etcd_count}"
  vcable = "${element(opc_compute_instance.etcd_nodes.*.vcable, count.index)}"
  parent_pool = "ipreservation:${element(opc_compute_ip_reservation.etcd_node_reservations.*.name, count.index)}"
}

resource "opc_compute_ip_association" "worker_node_ip_associations" {
  count = "${var.worker_count}"
  vcable = "${element(opc_compute_instance.worker_nodes.*.vcable, count.index)}"
  parent_pool = "ipreservation:${element(opc_compute_ip_reservation.worker_node_reservations.*.name, count.index)}"
}

# Create security rule to allow nodes within the cluster to access each other via the public IPs
resource "opc_compute_security_list" "kismatic-cluster" {
  name = "kismatic-cluster"
  policy = "DENY"
  outbound_cidr_policy = "PERMIT"
}

resource "opc_compute_sec_rule" "kismatic-cluster" {
  name = "kismatic-cluster"
  # source_list = "seciplist:${opc_compute_security_ip_list.kismatic-cluster.name}"
  source_list = "seciplist:/oracle/public/public-internet"
  destination_list = "seclist:${opc_compute_security_list.kismatic-cluster.name}"
  action = "permit"
  application = "/oracle/public/all"
  disabled = false
}

resource "opc_compute_security_association" "bootstrap_node_sec_associations" {
  vcable = "${opc_compute_instance.bootstrap_node.vcable}"
  seclist = "${opc_compute_security_list.kismatic-cluster.name}"
}

resource "opc_compute_security_association" "master_node_sec_associations" {
  count = "${var.master_count}"
  vcable = "${element(opc_compute_instance.master_nodes.*.vcable, count.index)}"
  seclist = "${opc_compute_security_list.kismatic-cluster.name}"
}

resource "opc_compute_security_association" "etcd_node_sec_associations" {
  count = "${var.etcd_count}"
  vcable = "${element(opc_compute_instance.etcd_nodes.*.vcable, count.index)}"
  seclist = "${opc_compute_security_list.kismatic-cluster.name}"
}

resource "opc_compute_security_association" "worker_node_sec_associations" {
  count = "${var.worker_count}"
  vcable = "${element(opc_compute_instance.worker_nodes.*.vcable, count.index)}"
  seclist = "${opc_compute_security_list.kismatic-cluster.name}"
}

#
resource "null_resource" "install-kismatic" {
  triggers {
    # make resource dependent on all nodes being available
    instances = "${opc_compute_instance.bootstrap_node.id},${join(",", opc_compute_instance.master_nodes.*.id)},${join(",", opc_compute_instance.etcd_nodes.*.id)},${join(",", opc_compute_instance.worker_nodes.*.id)}"
  }
  connection {
    type = "ssh"
    host = "${opc_compute_ip_reservation.bootstrap_node_ip_reservation.ip}"
    private_key = "${file("kismatic_id_rsa")}"
    user  = "${var.ssh_user}"
    timeout = "5m"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir ./kismatic && cd ./kismatic",
      "sudo apt update",
      "sudo apt -y install git build-essential",
      "sudo apt -y install -qq python2.7 && sudo ln -f -s /usr/bin/python2.7 /usr/bin/python",
      "curl -LO https://github.com/apprenda/kismatic/releases/download/v${var.kismatic_version}/kismatic-v${var.kismatic_version}-linux-amd64.tar.gz",
      "tar -xzf kismatic-v${var.kismatic_version}-linux-amd64.tar.gz && rm kismatic-v${var.kismatic_version}-linux-amd64.tar.gz",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl",
      "tee kismatic-cluster.yaml <<EOF ${data.template_file.kismatic-cluster-yaml.rendered}",
      "EOF"
    ]
  }
  provisioner "file" {
    source = "${var.ssh_public_key}"
    destination = "./kismatic/kismatic_id_rsa.pub"
  }
  provisioner "file" {
    source = "${var.ssh_private_key}"
    destination = "./kismatic/kismatic_id_rsa"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod go-r ./kismatic/kismatic_id_rsa",
      "cd ./kismatic",
      "./kismatic install apply -f kismatic-cluster.yaml --verbose"
    ]
  }
}

output "bootstrap_ip" {
    value = "${opc_compute_ip_reservation.bootstrap_node_ip_reservation.ip}"
}
