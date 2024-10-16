component "networking" {
  source = "./1_networking"
  providers = {
    tfe = provider.tfe.this
    hcp = provider.hcp.this
  }
  inputs = {
    region = var.region
    stack_id = var.stack_id
  }
}