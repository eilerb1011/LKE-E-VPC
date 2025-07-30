resource "linode_vpc" "lke_managed" {
  id = 55555
  label = "ThishouldBe lke+your clusterID"
  region      = var.region
  }
resource "linode_vpc_subnet" "lke_managed_subnet" {
  id = 22222
  vpc_id = linode_vpc.lke_managed.id
  ipv4 = "10.0.0.0/8"
  label = "managed-subnet"
}
