
variable user {}
variable password {}
variable domain {}
variable endpoint {}

variable kismatic_version {
  description = "Kismatic version"
  default = "1.2.1"
}

variable image {
  description = "Name of the image to use"
  default     = "/Compute-usorclptsc53098/stephen.cross@oracle.com/Ubuntu.16.04-LTS.amd64.20161130"
}

variable ssh_user {
  description = "User account for ssh access to the image"
  default     = "ubuntu"
}

variable ssh_private_key {
  description = "Path to the private ssh key file"
  default     = "./kismatic_id_rsa"
}

variable ssh_public_key {
  description = "Path to the private ssh key file"
  default     = "./kismatic_id_rsa.pub"
}

variable cluster_tag {
  description = "A unique tag for the cluster"
  default     = "kismatic-demo-cluster"
}

variable master_count {
  description = "Number of k8s master nodes"
  default     = 1
}

variable etcd_count {
  description = "Number of etcd nodes"
  default     = 1
}

variable worker_count {
  description = "Number of k8s worker nodes"
  default     = 1
}

variable ingress_count {
  description = "Number of k8s ingress nodes"
  default     = 0
}

variable storage_count {
  description = "Number of k8s storage nodes"
  default     = 0
}
