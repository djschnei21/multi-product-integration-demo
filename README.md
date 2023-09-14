# Multi Product Integration Demo

## Overview 

This repository is intended to help members of WWTFO quickly create reproducable demo environments which showcase:
- HCP Vault
- HCP Consul
- HCP Boundary
- HCP Packer
- Nomad Enterprise
- Terraform (TFC)

More importantly, the resulting environment is preconfigured to highlight the "better together" story, with a focus on interproduct integrations.  

The following integrations are utilized:
- **Terraform** is leveraged to deploy, configure, and integrate the other products
- **Vault** is used for dynamic credentials in several locations:
  - Dynamic Provider credentials used by **Terraform**
  - SSH signed Certificate injection in **Boundary**
  - Dynamic MongoDB credentials injection via **Nomad** templates
- **Packer** is used to create **Nomad** Server and Client AMIs in AWS
- **Terraform** queries **HCP Packer** for AMI management
- **Consul** service registration via **Nomad** 
- **Consul** Connect (service mesh) used for **Nomad** job east/west communication

## Repository Structure

The entire environment is orchestrated by the "control-workspace" directory.  After completing a few prerequesite manual operations (which we will discuss below in the "Prerequisites" section), you will plan/apply the "control-workspace" in TFC.  This workspace will orchestrate the creation and triggering of all downstream workspaces (Shoutout to @lucymhdavies for the multi-space idea!).  
- **control-workspace**:  Orchestrates all other workspaces
- **networking**: Creates a VPC in AWS with 3 subnets, an HVN in HCP, and the peering connection between the two
- **hcp-clusters**: Creates an HCP Vault cluster, an HCP Boundary cluster, an HCP Consul cluster within the HVN
- **vault-auth-config**: On the first run, will utilize the root token generated in **hcp-clusters** to bootstrap Vault JWT Auth for Terraform Cloud.  After the first run this JWT Auth will be leverage by TFC for all subsequent runs
- **boundary-config**: Will configure the Boundary instance, configure the dynamic host catalogues, and integrate Vault for SSH signed cert injection
- **nomad-cluster**: Provisions a 3 node Nomad server cluster as an AWS ASG, boostraps its ACLs, and stores the bootstrap token in Vault
- **nomad-nodes**: Provisions 2 ASGs of 2 nodes each.  1 node pool for x86 nodes and 1 node pool for ARM nodes
- **workload**: Deploys 2 jobs to the Nomad cluster and configures Vault for dynamic MongoDB credentials:
  - Job 1 provisions a MongoDB instance
  - Integrates a Vault MongoDB secrets engine with the MongoDB instance
  - Job 2 provisions a frontend webapp, injecting credentials from vault, leveraging Consul connect for service communication

## Prerequisites

- You need a doormat created AWS sandbox account
- You need a HCP account with an organization scoped service principal
- You need a TFC account, a TFC Project, and a TFC user token 
- You need a pre-configured OAuth connection between TFC and GitHub

Preparing your AWS account to leverage the doormat provider on TFC:

1) `cd doormat-prereqs/`
2) paste your doormat generated AWS credentials, exporting them to your shell
```
export AWS_ACCESS_KEY_ID=************************
export AWS_SECRET_ACCESS_KEY=************************
export AWS_SESSION_TOKEN=************************
```
3) `terraform init`
4) Run a plan passing in your TFC account name.  For example `terraform plan -var "tfc_organization=something"`
5) Assuming everything looks good, run an aaply passing in your TFC account name `terraform apply -var "tfc_organization=something"`

Preparing your TFC account:

1) Create a new Project (I called mine "hashistack")
2) Create a new Variable Set (again, I called mine "hashistack") and scope it to your previously created Project
3) Populate the variable set with the following variables:

| Key | Value | Sensitive? | Type |
|-----|-------|------------|------|
|boundary_admin_password|<intended boundary admin password>|yes|terraform|
|my_email|<your email>|no|terraform|
|nomad_license|<your nomad ent license>|yes|terraform|
|region|<the region which will be used on HCP and AWS>|no|terraform|
|stack_id|<will be used to consistently name resources>|no|terraform|
|tfc_organization|<your TFC account name>|no|terraform|
|HCP_CLIENT_ID|<HCP Service Principal Client ID>|no|env|
|HCP_CLIENT_SECRET|<HCP Service Principal Client Secret>|yes|env|
|HCP_PROJECT_ID|<your HCP Project ID retrieved from HCP>|no|env|
|TFC_WORKLOAD_IDENTITY_AUDIENCE|<can be literally anything>|no|env|
|TFE_TOKEN|<TFC User token>|yes|env|

4) Create a new workspace within your TFC project called "0_control-workspace", attaching it to this VCS repository, specifying the working directory as "control-workspace"
5) Create the following workspace variables within "0_control-workspace":

| Key | Value | Sensitive? | Type |
|-----|-------|------------|------|
|oauth_token_id|<the ot- ID of your OAuth connection>|no|terraform|
|repo_identifier|djschnei21/multi-cloud-hashistack|no|terraform|
|tfc_project_id|<the prj- ID of your TFC Project>|no|terraform|