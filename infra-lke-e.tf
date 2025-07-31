terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "3.1.1"
    }
  }
}
//Use the Linode Provider for LKE-E
provider "linode" {
  token = var.token
  api_version = "v4beta"
}

//Use the Linode Provider for LKE
//provider "linode" {
//  token = var.token
//}

//Use the linode_lke_cluster resource to create
//a Kubernetes cluster as usual
resource "linode_lke_cluster" "cluster1" {
  //k8s_version is used in both LKE and LKE-E - but with LKE-E you need to pull available versions from the v4beta api using:
  //curl https://api.linode.com/v4beta/lke/tiers/enterprise/versions -H "Authorization: Bearer $token"
  
  k8s_version = var.k8s_version
  label       = var.label
  region      = var.region
  //control_plane high_availability is not needed in LKE-E, but acl is enabled by default - so IPs need specified or quad 0s
  control_plane  {
  //      high_availability = var.HA
         acl {
            enabled = true
            addresses {
                ipv4 = ["0.0.0.0/0"]
                ipv6 = ["2001:db8::/32"]
            }	
    }
  }
  tier = "enterprise"
  dynamic "pool" {
    for_each = var.pools
    content {
      type  = pool.value["type"]
      count = pool.value["min-nodes"]
      autoscaler {
        min = pool.value["min-nodes"]
        max = pool.value["max-nodes"]
        }
      }
    }
  }
output "kubeconfig1" {
  value     = linode_lke_cluster.cluster1.kubeconfig
  sensitive = true
}
output "clusterid" {
  value = linode_lke_cluster.cluster1.id
}
