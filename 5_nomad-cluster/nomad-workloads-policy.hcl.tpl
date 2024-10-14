path "secret/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "secret/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "secret/metadata/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/*" {
  capabilities = ["list"]
}

path "secret/metadata/*" {
  capabilities = ["list"]
}