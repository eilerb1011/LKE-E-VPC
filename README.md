# LKE-E-VPC
Terraform for LKE-E with additional VPC subnets

## Build the LKE-E Cluster
The infra-lke-e.tf file is a base k8s tf deployment with some lines commented out, and some lines added to adjust LKE to LKE-E. To deploy, use infra-lke-e.tf, variables.tf and terraform.tfvars - keep the rest of the files out for now.

Some of the highlights - 
1. the provider config now specifies v4beta
2. the control_plane arguement for HA is commented out, as the HA part is no longer valid with a dedicated control plane in LKE-E
   - HOWEVER - if you use control plane acl, it is still specified here, and IS enabled by default. You can modify the CIDRs in the block.
3. You can modify the follwing in the tfvars file to suit your needs:

   a. region - you can deploy in any region LKE-E exists
     - You can find these regions using this API command:
     - `curl https://api.linode.com/v4/regions -H "Authorization: Bearer $token" | jq '.data[] | select(.capabilities[] == "Kubernetes Enterprise") | {id: .id, label:.label}' `
   
   b. k8s_version = "...."
   - You can pull current versions here:
   - `curl https://api.linode.com/v4beta/lke/tiers/enterprise/versions -H "Authorization: Bearer $token" | jq'`
     
   c. Modify your pools with min/max node numbers and the type of node you want to deploy.
   - Node types are available here:
   - `curl https://api.linode.com/v4/linode/types -H "Authorization: Bearer $token" | jq '.data[] | {id: .id, label:.label}'`
   - **Note** You cannot use types noted with -edge in LKE. GPU Plans are also only in specific regions, you can obtain this by using this command:
   - `curl https://api.linode.com/v4/regions -H "Authorization: Bearer $token" | jq '.data[] | select(.capabilities[] == "GPU Linodes") | {id: .id, label:.label}' `
     
After deployment use your kubeconfig as usual by pulling it from tf outputs:
```
terraform output -raw kubeconfig1 >> kube1.yaml
base64 -d -w0 kube1.yaml >> kubeconfig.yaml
```
## Modify and Integrate the VPC
Now - if you want to add a subnet to the k8s VPC - you can do this via API or TF. However, you will need to deploy the manifest route-add.yaml in this archive in order to route from the nodes and pods to your subnet due to the architecture of LKE-E. Adjust the subnet in the yaml from 172.16.0.0/16 to fit your need, this should match whatever you use in `vpc.tf` when you modify the vpc with your new subnet.

In order to add subnets to the vpc via TF, you will need to import the VPC and VPC subnet created by Akamai during the creation of the LKE Cluster by adding the `vpc.tf` file from this archive into your environment and adjusting the following fields with values from your account. You will need to gather these items:
 - **LKE ClusterID**
 - **vpc_id**
  - **subnet_id**
  You will get these by doing this:
 ```
 terraform output clusterid
```
 run this command to see your nodes:
 ```
 curl https://api.linode.com/v4beta/lke/clusters/PUT_CLUSTER_ID_HERE/pools -H "Authorization: Bearer $token" | jq
```
Now from any of the nodes in the nodepool, take the `instance_id` - it does not matter which node you use for this.

Run this command, replacing the long string with your actual ID:
```
curl https://api.linode.com/v4beta/linode/instances/THE-instance_id-OF_YOUR_NODE/configs -H "Authorization: Bearer $token" | jq
```
And down in the list you will see an `interfaces` object with the `vpc_id` and `subnet_id` that you will need to plug in to the `vpc.tf` file.
 ```
       "interfaces": [
        {
          "id": -configID-,
          "purpose": "vpc",
          "primary": false,
          "active": true,
          "ipam_address": null,
          "label": null,
          "vpc_id": YourVPCid,
          "subnet_id": YOURsubnetID,
          "ipv4": {
            "vpc": "10.0.0.2",
            "nat_1_1": null
          },
 ```
Now open the `vpc.tf` file and make the following mods:
```
resource "linode_vpc" "lke_managed" {
  id = Type the vpc_id numbers here - no quotes
  label = this should read "lkexxxxx" in quotes, where xxxxx = your clusterID 
  region      = var.region
  }
resource "linode_vpc_subnet" "lke_managed_subnet" {
  **id = Type the subnet_id numbers here - no quotes**
  vpc_id = linode_vpc.lke_managed.id
  ipv4 = "10.0.0.0/8" 
  label = "managed-subnet"
}
```

Then do an import of the managed vpc and managed subnet with the following:
```
terraform import linode_vpc.lke_managed REPLACEwithYOURvpcID
terraform import linode_vpc_subnet.lke_managed_subnet REPLACEwithYOURvpcID,REPLACEwithYOURsubnetID
```
Example: if my vpcID is 55555 and my vpcSubnetID is 22222 my commands will looks like this:
```
terraform import linode_vpc.lke_managed 55555
terraform import linode_vpc_subnet.lke_managed_subnet 55555,22222
```
Now. re-open the `vpc.tf` file and delete the `id:` line from the `vpc` and `vpc_subnet` resources - since these are read-only fields in the API. Only the `id:` line from each.

You can now also add additional subnets like this in your `vpc.tf` file:
 ```
 resource "linode_vpc_subnet" "lke_customer_subnet_1" {
  vpc_id = linode_vpc.lke_managed.id
  ipv4 = "172.16.100.0/24" 
  label = "lke503536-Customer-1"
}
```
Just make sure you match up the route-add.yaml file with any subnets you create here. 
 
Run a `terraform apply` to create the new subnet in your LKE-E vpc, The vpcid and NEW subnetid can now be attached to linodes you create. See below:

Enable routing to the vpc from the hosts by running the daemonset route-add.yaml with `kubectl apply -f route-add.yaml`

The last thing you will need to do is adjust the fw policies to match. These too can be imported into TF in the same manner - this of course if only necessary if you are initiating the connection from outside the cluster to in. Connections from the cluster to the newly created (by you) subnets are already being curated by you. These policies will need to allow the LKE subnet inbound (10.0.0.0/8) to ensure traffic flow.

## Add a Linode and Test Communication
Now you can deploy the instance.tf file included here. This is purely for testing, so change anything really except the following fields:
```
  region          = var.region
```
And the entire interface block should not be changed:
```
  interface {
    purpose   = "vpc"
    subnet_id = linode_vpc_subnet.lke_customer_subnet_1.id
    primary = true
    ipv4 {
      nat_1_1 = "any"
    }
  }
```
This TF will create an instance using the subnet ID of the newly created subnet within the VPC in your current region where LKE-E resides.
