//Use the Linode Provider
//provider "linode" {
//  token = var.token
//}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster
resource "linode_vpc" "lke_managed" {
  label = "lke503536" 
  region      = var.region
  }
resource "linode_vpc_subnet" "lke_managed_subnet" {
  vpc_id = linode_vpc.lke_managed.id
  ipv4 = "10.0.0.0/8" 
  label = "managed-subnet"
}
resource "linode_vpc_subnet" "lke_customer_subnet_1" {
  vpc_id = linode_vpc.lke_managed.id
  ipv4 = "172.16.100.0/24" 
  label = "lke503536-Customer-1"
}

