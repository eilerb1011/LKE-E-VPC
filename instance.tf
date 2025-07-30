resource "linode_instance" "Linux" {
  label           = "k8sVPCtest"
  image           = "linode/ubuntu22.04"
  region          = var.region
  type            = "g6-standard-1"
  root_pass       = "R@nd01ns3cur3p@$$w0rd!"

  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.lke_customer_subnet_1.id
    primary = true
    ipv4 {
      nat_1_1 = "any"
    }
  }
}
