Deploying Kubernetes on Oracle Compute using Terraform and Kismatic
===================================================================

This Terraform configuration brings up a basic Kubernetes infrastructure on Oracle Compute Cloud using the [Kismatic Enterprise Toolkit](https://github.com/Apprenda/Kismatic).

Based on the [hands-on-with-kubernetes-workshop](https://github.com/swade1987/hands-on-with-kubernetes-workshop) delivered by @swade1987 at the February 2017 [Kubernetes Ottawa Meetup](https://www.meetup.com/Kubernetes-Ottawa/events/236992039/). This example combines the deployment steps into a single Terraform confirguration for the [Oracle Compute Cloud](http://cloud.oracle.com/).

In this example all nodes are deployed on the Oracle Compute Cloud on the shared network, and each node is also assigned a floating public IP address. The Kismatic Enterprise Toolkit is installed to a bootstrap node which in turn sets up Kubernetes infrastructure on the master, etcd and worker nodes using Kismatic.

Setup
-----

1.	Get an [Oracle Compute Cloud account](https://cloud.oracle.com/tryit)
2.	Download [Terraform](http://terraform.io) to your local machine (release 0.9.4 or later)

Now clone this repository

```
$ git clone https://github.com/scross01/oracle-cloud-examples
$ cd oracle-cloud-examples/kismatic
```

Create/update the local `terraform.tfvars` with the required account credentails

```
user = "xxxx@example.com"
password = "xxxx"
domain = "xxxx"
endpoint = "https://api-z27.compute.us6.oraclecloud.com/"
```

The default deployment parameters can also be added to the `terraform.tfvars`

```
master_count = 1
etcd_count = 1
worker_count = 1
ingress_count = 0
storage_count = 0
```

#### Ensure the base OS image is available

If you are using a base OS image other than the default public Oracle Linux image, ensure the image is available in your compute domain and reference the image with the fully qualify name in the `terraform.tfvars`. Alternative OS images can be obtained from the [Oracle Cloud Marketplace](https://cloud.oracle.com/marketplace/product/compute).

```
image = "/Compute-usorclptsc53098/stephen.cross@oracle.com/Ubuntu.16.04-LTS.amd64.20161130"
```

#### Generate an SSH Key

The default configuraiton assumes that the ssh key files `kismatic_id_rsa` and `kismatic_is_rsa.pub` are in the local directory. This is the SSH key to SSH to each of the nodes. Gerneate the SSH key file or override the variable `kismatic-cluster-ssh-key`

```sh
$ ssh-keygen -f kismatic_id_rsa -N "" -q
```

Deploy the insfrastructure
--------------------------

To see the changes which are going to be made execute the following command:

```
$ terraform plan
```

To apply the changes execute the following command:

```
$ terraform apply
```

### Run the sample app

#### Connect to the bootstrap server

The public IP address of bootstrap node is output at the end of the terraform configuraiton, and can also be found by running:

```
$ terraform output bootstrap_ip
```

Connect to the bootstramp node using the SSH key that was created.

```
$ ssh ubuntu@<bootstrap_ip> -i kismatic_id_rsa
[opc@bootstrap_node]
```

The kismatic installation and configuration files are located in the `kismatic` directory.

#### Download and run the example app

Download and deploy the demo app from the [hands-on-with-kubernetes-workshop](https://github.com/swade1987/hands-on-with-kubernetes-workshop)

```
[opc@bootstrap_node] $ git clone https://github.com/swade1987/hands-on-with-kubernetes-workshop
```

See the [hands-on-with-kubernetes-workshop Cheatsheet](https://github.com/swade1987/hands-on-with-kubernetes-workshop/blob/master/cheatsheet.md) for the next steps

Cleanup
-------

To clean up and destroy all nodes and related configuration

```
$ terraform destroy
```
