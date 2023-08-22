terraform {
  required_providers {
    tfe = {
      version = "~> 0.46.0"
    }
  }
}

provider "tfe" {}

resource "tfe_workspace" "networking" {
  name          = "1_networking"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "networking"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ tfe_workspace.hcp_clusters.id ]
}

resource "tfe_workspace" "hcp_clusters" {
  name          = "2_hcp-clusters"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "hcp-clusters"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ tfe_workspace.nomad_cluster.id, tfe_workspace.boundary_config.id, tfe_workspace.workload.id ]
}

resource "tfe_workspace" "vault_auth_config" {
  name          = "3_vault-auth-config"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "vault-auth-config"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ tfe_workspace.nomad_nodes.id, tfe_workspace.workload.id ]
}

resource "tfe_workspace" "nomad_cluster" {
  name          = "4_nomad-cluster"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "nomad-cluster"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ tfe_workspace.nomad_nodes.id, tfe_workspace.workload.id ]
}

resource "tfe_workspace" "boundary_config" {
  name          = "5_boundary-config"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "boundary-config"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ ]
}

resource "tfe_workspace" "nomad_nodes" {
  name          = "6_nomad-nodes"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "nomad-nodes"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ ]
}

resource "tfe_workspace" "workload" {
  name          = "7_workload"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id

  vcs_repo {
    identifier = var.repo_identifier
    oauth_token_id = var.oauth_token_id
  }

  working_directory = "workload"
  queue_all_runs = false
  assessments_enabled = false
  remote_state_consumer_ids = [ ]
}

resource "tfe_workspace_run" "networking" {
  workspace_id    = tfe_workspace.networking.id

  apply {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
}

resource "tfe_workspace_run" "hcp_clusters" {
  depends_on = [ tfe_workspace_run.networking ]
  workspace_id    = tfe_workspace.hcp_clusters.id

  apply {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
}

resource "tfe_workspace_run" "nomad_cluster" {
  depends_on = [ tfe_workspace_run.hcp_clusters ]
  workspace_id    = tfe_workspace.nomad_cluster.id

  apply {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
}

resource "tfe_workspace_run" "boundary_config" {
  depends_on = [ tfe_workspace_run.nomad_cluster ]
  workspace_id    = tfe_workspace.boundary_config.id

  apply {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
}

resource "tfe_workspace_run" "nomad_nodes" {
  depends_on = [ tfe_workspace_run.nomad_cluster ]
  workspace_id    = tfe_workspace.nomad_nodes.id

  apply {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
  destroy {
    manual_confirm    = false
    wait_for_run      = true
    retry_attempts    = 5
    retry_backoff_min = 5
  }
}