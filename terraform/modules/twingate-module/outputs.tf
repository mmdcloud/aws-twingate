output "remote_network_id" {
  description = "ID of the Twingate remote network"
  value       = twingate_remote_network.this.id
}

output "remote_network_name" {
  description = "Name of the Twingate remote network"
  value       = twingate_remote_network.this.name
}

output "connector_ids" {
  description = "Map of connector names to IDs"
  value       = { for k, v in twingate_connector.this : k => v.id }
}

output "connector_tokens" {
  description = "Map of connector access and refresh tokens (sensitive)"
  value = {
    for k, v in twingate_connector_tokens.this : k => {
      access_token  = v.access_token
      refresh_token = v.refresh_token
    }
  }
  sensitive = true
}

output "user_ids" {
  description = "Map of user emails to IDs"
  value       = { for k, v in twingate_user.this : k => v.id }
}

output "group_ids" {
  description = "Map of group names to IDs"
  value       = { for k, v in twingate_group.this : k => v.id }
}

output "resource_ids" {
  description = "Map of resource names to IDs"
  value       = { for k, v in twingate_resource.this : k => v.id }
}

# Individual connector outputs for easy access
output "first_connector_access_token" {
  description = "Access token for the first connector (if exists)"
  value       = try(values(twingate_connector_tokens.this)[0].access_token, null)
  sensitive   = true
}

output "first_connector_refresh_token" {
  description = "Refresh token for the first connector (if exists)"
  value       = try(values(twingate_connector_tokens.this)[0].refresh_token, null)
  sensitive   = true
}