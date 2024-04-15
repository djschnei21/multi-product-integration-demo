# Multi Product Integration Demo

## Overview 

This repository is intended to help members of WWTFO quickly create reproducable demo environments which showcase:
- HCP Vault
- HCP Consul
- HCP Boundary
- HCP Packer
- Nomad Enterprise
- Terraform (TFC)

More importantly, the resulting environment is preconfigured to highlight the "better together" story, with a focus on interproduct integrations. A demo could span the entire environment or focus on any individual aspect.  The aim was to provide a very flexible environment which can be used as the basis for all usecase demos.

The following integrations are highlighted by default:
- **Terraform** is leveraged to deploy, configure, and integrate the other products
- **Vault** is used for dynamic credentials in several locations:
  - Dynamic Provider credentials used by **Terraform**
  - SSH signed Certificate injection in **Boundary**
  - Dynamic MongoDB credentials injection via **Nomad** templates
- **Packer** is used to create **Nomad** Server and Client AMIs in AWS
- **Terraform** integrates with **HCP Packer** for AMI management
- **Consul** service registration via **Nomad** 
- **Consul** Connect (service mesh) used by **Nomad** jobs

## Repository Structure

The entire environment is orchestrated by the "control-workspace" directory.  After completing a few prerequesite manual operations (which we will discuss below in the "Prerequisites" section), you will plan/apply the "control-workspace" in TFC.  This workspace will orchestrate the creation and triggering of all downstream workspaces (Shoutout to @lucymhdavies for the multi-space idea!).  
- **control-workspace**:  Orchestrates all other workspaces
- **networking**: Creates a VPC in AWS with 3 subnets, an HVN in HCP, and the peering connection between the two
- **hcp-clusters**: Creates an HCP Vault cluster, an HCP Boundary cluster, an HCP Consul cluster within the HVN
- **vault-auth-config**: On the first run, will utilize the root token generated in **hcp-clusters** to bootstrap Vault JWT Auth for Terraform Cloud.  After the first run this JWT Auth will be leverage by TFC for all subsequent runs that require Vault access
- **boundary-config**: Will configure the Boundary instance, configure the dynamic host catalogues, and integrate Vault for SSH signed cert injection
- **nomad-cluster**: Provisions a 3 node Nomad server cluster as an AWS ASG, boostraps its ACLs, and stores the bootstrap token in Vault
- **nomad-nodes**: Provisions 2 ASGs of 2 nodes each.  1 node pool for x86 nodes and 1 node pool for ARM nodes

## Prerequisites

- You need a doormat created AWS sandbox account [Docs](https://docs.prod.secops.hashicorp.services/doormat/aws/create_individual_sandbox_account/)
- You need a doormat enrolled TFC Account [Docs - Only Steps 1-5!](https://docs.prod.secops.hashicorp.services/doormat/tf_provider/#onboard-tfc-organization-to-doormat)
- You need a HCP account with an organization scoped service principal [Docs](https://developer.hashicorp.com/hcp/docs/hcp/admin/iam/service-principals#organization-level-service-principals-1)
- You need a Packer Registry Initialized within your HCP Project [Docs](https://developer.hashicorp.com/hcp/docs/packer/manage-registry#view-and-change-registry-tier)
- You need a TFC account and a TFC user token [Docs](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/users#tokens)
- You need a pre-configured OAuth connection between TFC and GitHub [Docs](https://developer.hashicorp.com/terraform/cloud-docs/vcs/github)
  - Once created, note your OAuth Token ID.  This can be found by navigating in TFC to Org "Settings" --> "Version Control - Providers" --> "OAuth Token Id"

### Preparing your HCP Packer Registry

1) You must enable the HCP Packer registry before Packer can publish build metadata to it. Click the Create a registry button after clicking on the Packer link under "Services" in the left navigation. This only needs to be done once.

### Preparing your AWS account to leverage the doormat provider on TFC:

1) navigate to the doormat-prereqs directory
```
cd doormat-prereqs/
```
2) paste your doormat generated AWS credentials, exporting them to your shell
```
export AWS_ACCESS_KEY_ID=************************
export AWS_SECRET_ACCESS_KEY=************************
export AWS_SESSION_TOKEN=************************
```
3) Initialize terraform
```
terraform init
```
4) Run a plan passing in your TFC account name
```
terraform plan -var "tfc_organization=something"
```
5) Assuming everything looks good, run an apply passing in your TFC account name 
```
terraform apply -var "tfc_organization=something"
```

### Preparing your TFC account:

1) Create a new Project (I called mine "hashistack")
2) Create a new Variable Set (again, I called mine "hashistack") and scope it to your previously created Project
3) Populate the variable set with the following variables:

| Key | Value | Sensitive? | Type |
|-----|-------|------------|------|
|aws_account_id|\<your AWS account ID\>|no|terraform|
|boundary_admin_password|\<intended boundary admin password\>|yes|terraform|
|my_email|\<your email\>|no|terraform|
|nomad_license|\<your nomad ent license\>|yes|terraform|
|region|\<the region which will be used on HCP and AWS\>|no|terraform|
|stack_id|\<will be used to consistently name resources - 3-36 characters.  Can only contain letters, numbers and hyphens\>|no|terraform|
|tfc_organization|\<your TFC account name\>|no|terraform|
|HCP_CLIENT_ID|\<HCP Service Principal Client ID\>|no|env|
|HCP_CLIENT_SECRET|\<HCP Service Principal Client Secret\>|yes|env|
|HCP_PROJECT_ID|\<your HCP Project ID retrieved from HCP\>|no|env|
|TFC_WORKLOAD_IDENTITY_AUDIENCE|\<can be literally anything\>|no|env|
|TFE_TOKEN|\<TFC User token\>|yes|env|
|TFC_ORGANIZATION|\<your TFC account name\>|no|env|

4) Create a new workspace within your TFC project called "0_control-workspace", attaching it to this VCS repository, specifying the working directory as "0_control-workspace"
5) Create the following workspace variables within "0_control-workspace":

| Key | Value | Sensitive? | Type |
|-----|-------|------------|------|
|oauth_token_id|\<the ot- ID of your OAuth connection\>|no|terraform|
|repo_identifier|<your GH org>/multi-product-integration-demo|no|terraform|
|repo_branch|main|no|terraform|
|tfc_project_id|\<the prj- ID of your TFC Project\>|no|terraform|

## Building the Nomad AMI using Packer

1) navigate to the packer directory
```
cd packer/
```
2) paste your doormat generated AWS credentials, exporting them to your shell
```
export AWS_ACCESS_KEY_ID=************************
export AWS_SECRET_ACCESS_KEY=************************
export AWS_SESSION_TOKEN=************************
```
3) export your HCP_CLIENT_ID, HCP_CLIENT_SECRET, and HCP_PROJECT_ID to your shell
```
export HCP_CLIENT_ID=************************                                    
export HCP_CLIENT_SECRET=************************
export HCP_PROJECT_ID=************************
```
4) Trigger a packer build specifying a pre-existing, publicly accesible subnet of your AWS account and your targetted region for build to happen within
```
packer build -var "subnet_id=subnet-xxxxxxxxxxxx" -var "region=xxxxx" ubuntu.pkr.hcl
```

## Triggering the deployment

Now comes the easy part, simply trigger a run on "0_control-workspace" and watch the environment unfold! 

Once the run is complete, you can access each tool by:
- **HCP Consul**: Navigate to the cluster in HCP and generate an admin token
- **HCP Vault**: Navigate to the cluster in HCP and generate an admin token
- **HCP Boundary**: Navigate to the cluster in HCP or via the Desktop app:
  - *username*: admin
  - *password*: this is whatever you set in the variable set
- **Nomad Ent**: The "5_nomad-cluster" workspace will have an output containing the public ALB endpoint to access the Nomad UI.  The Admin token for this can be retrieved from Vault using
```
vault kv get -mount=hashistack-admin/ nomad_bootstrap/SecretID
```

## Deploy a workload to highlight the integrations

To demonstrate the full stack and all the pre-configured integrations, we've created a "no-code" module.  The code for this module is located within the following repository [terraform-nomad-workload](https://github.com/djschnei21/terraform-nomad-workload)
1) Fork the repository (temporarily necessary)
2) Open your TFC Org's Registry and click "publish" then "module"
3) Select your Github Connection
4) Select your forked repository "terraform-nomad-workload"
5) Select "Branch" based, then branch = "main" and version = "1.0.0"
6) Select "Add Module to no-code provision allowlist" 
7) Publish
8) [OPTIONAL] Once the module has been published, go to "Configure Settings" and click "Edit Versions and Variable Settings":
- tfc_organization: <your tfc org name>
- region: <the region you deployed the HashiStack to>
- mongodb_image: "mongo:5" (you may also add others to show variability, but during your demo always use v5)
- frontend_app_image: "huggingface/mongoku:1.3.0" (you may also add others to show variability, but during your demo always use v1.3.0)
- Save changes
9) To demo the workload, select "provision workspace", then enter the following variables for the workspace:
- create_consul_intention: true
- frontend_app_image: "huggingface/mongoku:1.3.0"
- mongodb_image: "mongo:5"
- region: <the region you deployed the HashiStack to>
- stack_id: <name your demo app> (I typically use something like "app001-dev")
- tfc_organization: <your tfc org name>
10) Click "Next: Workspace Settings"
11) Provide the workspace settings:
- Workspace name: <Name the workspace> (I typically use the stack_id I used above, "app001-dev")
- Project: <must be the same project the HashiStack was deployed to> (e.g. "HashiStack")
- Click "Create Workspace"
![](https://github.com/djschnei21/multi-product-integration-demo/blob/main/plan.png?raw=true)

### Video Walkthrough of workload deployment
![](https://drive.google.com/file/d/1GckbTYTFcxwkvgboHW1jwbkmRvVUB9HA/view?usp=sharing)
