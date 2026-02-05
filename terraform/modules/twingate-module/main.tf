# -----------------------------------------------------------------------------------------
# Twingate Remote Network
# -----------------------------------------------------------------------------------------
resource "twingate_remote_network" "this" {
  name     = var.remote_network_name
}

# -----------------------------------------------------------------------------------------
# Twingate Connector
# -----------------------------------------------------------------------------------------
resource "twingate_connector" "this" {
  for_each = { for idx, c in var.connectors : idx => c }

  remote_network_id = twingate_remote_network.this.id
  name              = each.value.name
}

# -----------------------------------------------------------------------------------------
# Twingate Connector Tokens
# -----------------------------------------------------------------------------------------
resource "twingate_connector_tokens" "this" {
  for_each = twingate_connector.this

  connector_id = each.value.id
}

# -----------------------------------------------------------------------------------------
# Twingate Users
# -----------------------------------------------------------------------------------------
resource "twingate_user" "this" {
  for_each = { for user in var.users : user.email => user }

  first_name = each.value.first_name
  last_name  = each.value.last_name
  email      = each.value.email
  role       = each.value.role
  is_active  = lookup(each.value, "is_active", true)
}

# -----------------------------------------------------------------------------------------
# Twingate Groups
# -----------------------------------------------------------------------------------------
resource "twingate_group" "this" {
  for_each = { for group in var.groups : group.name => group }

  name     = each.value.name
  user_ids = each.value.user_ids
}

# -----------------------------------------------------------------------------------------
# Twingate Resources
# -----------------------------------------------------------------------------------------
resource "twingate_resource" "this" {
  for_each = { for resource in var.resources : resource.name => resource }

  name              = each.value.name
  address           = each.value.address
  remote_network_id = twingate_remote_network.this.id
  protocols = {
    allow_icmp = each.value.protocols.allow_icmp
    tcp        = each.value.protocols.tcp
    udp        = each.value.protocols.udp
  }

  dynamic "access_group" {
    for_each = each.value.access_groups
    content {
      group_id           = access_group.value.group_id
      security_policy_id = lookup(access_group.value, "security_policy_id", null)
    }
  }

  # alias              = lookup(each.value, "alias", null)
  # is_active          = lookup(each.value, "is_active", true)
  # is_visible         = lookup(each.value, "is_visible", true)
  # security_policy_id = lookup(each.value, "security_policy_id", null)
  # usage_based_autolock_duration_days = lookup(each.value, "usage_based_autolock_duration_days", null)
}