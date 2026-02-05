variable "remote_network_name" {
  description = "Name of the Twingate remote network"
  type        = string
}

variable "connectors" {
  description = "List of Twingate connectors to create"
  type = list(object({
    name = string
  }))
  default = []
}

variable "users" {
  description = "List of Twingate users to create"
  type = list(object({
    first_name = string
    last_name  = string
    email      = string
    role       = string
    is_active  = optional(bool, true)
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.users :
      contains(["ADMIN", "DEVOPS", "SUPPORT", "MEMBER"], user.role)
    ])
    error_message = "User role must be one of: ADMIN, DEVOPS, SUPPORT, MEMBER"
  }
}

variable "groups" {
  description = "List of Twingate groups to create"
  type = list(object({
    name     = string
    user_ids = list(string)
  }))
  default = []
}

variable "resources" {
  description = "List of Twingate resources to create"
  type = list(object({
    name    = string
    address = string
    protocols = object({
      allow_icmp = optional(bool, false)
      tcp = optional(object({
        policy = string
        ports  = optional(list(string), [])
      }))
      udp = optional(object({
        policy = string
        ports  = optional(list(string), [])
      }))
    })
    access_groups = list(object({
      group_id           = string
      security_policy_id = optional(string)
    }))
    alias                              = optional(string)
    is_active                          = optional(bool, true)
    is_visible                         = optional(bool, true)
    is_browsable                       = optional(bool, false)
    security_policy_id                 = optional(string)
    usage_based_autolock_duration_days = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for resource in var.resources :
      alltrue([
        for tcp in(lookup(resource.protocols, "tcp", null) != null ? [resource.protocols.tcp] : []) :
        contains(["RESTRICTED", "ALLOW_ALL", "DENY_ALL"], tcp.policy)
      ])
    ])
    error_message = "TCP policy must be one of: RESTRICTED, ALLOW_ALL, DENY_ALL"
  }

  validation {
    condition = alltrue([
      for resource in var.resources :
      alltrue([
        for udp in(lookup(resource.protocols, "udp", null) != null ? [resource.protocols.udp] : []) :
        contains(["RESTRICTED", "ALLOW_ALL", "DENY_ALL"], udp.policy)
      ])
    ])
    error_message = "UDP policy must be one of: RESTRICTED, ALLOW_ALL, DENY_ALL"
  }
}