terraform {
  required_providers {
    tfe = {
      version = "~> 0.46.0"
    }
  }
}

provider "tfe" {}

resource "tfe_workspace" "test" {
  name          = "networking"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    github_app_installation_id = var.github_app_installation_id 
  }
}