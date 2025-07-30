k8s_version = "v1.31.8+lke5"
##curl https://api.linode.com/v4beta/lke/tiers/enterprise/versions -H "Authorization: Bearer $token"
#####CLUSTER 1 Settings###############
label = "us-ord-k8s-ent-3"
region = "us-ord"
pools = {
  "pool-1" = {
    type = "g6-standard-4"
    min-nodes = 2
    max-nodes = 2
  }
}
