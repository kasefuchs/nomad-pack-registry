variable "job_name" {
  type    = string
  default = ""
}

variable "job_type" {
  type    = string
  default = "system"
}

variable "ui" {
  type = object({
    description = string
    links = list(
      object({
        label = string
        url   = string
      })
    )
  })
  default = null
}

variable "region" {
  type    = string
  default = "global"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "node_pool" {
  type    = string
  default = "all"
}

variable "datacenters" {
  type    = list(string)
  default = ["*"]
}

variable "constraints" {
  type = list(
    object({
      attribute = string
      operator  = string
      value     = string
    })
  )
  default = []
}

variable "network" {
  type = object({
    mode = string
    ports = list(
      object({
        name         = string
        to           = number
        static       = number
        host_network = string
      })
    )
    dns = object({
      servers  = list(string)
      searches = list(string)
      options  = list(string)
    })
  })
  default = {
    mode = "bridge"
    ports = [
      {
        name         = "envoy-proxy"
        to           = -1
        static       = 0
        host_network = "connect"
      },
      {
        name         = "service-check"
        to           = -1
        static       = 0
        host_network = "private"
      }
    ]
    dns = null
  }
}

variable "services" {
  type = list(
    object({
      name         = string
      port         = string
      tags         = list(string)
      provider     = string
      address      = string
      address_mode = string
      checks = list(
        object({
          address_mode = string
          args         = list(string)
          restart = object({
            limit           = number
            grace           = string
            ignore_warnings = bool
          })
          command         = string
          interval        = string
          method          = string
          body            = string
          name            = string
          path            = string
          expose          = bool
          port            = string
          protocol        = string
          task            = string
          timeout         = string
          type            = string
          tls_server_name = string
          tls_skip_verify = bool
          on_update       = string
          headers         = string
        })
      )
      connect = object({
        native = bool
        sidecar = object({
          task = object({
            resources = object({
              cpu    = number
              memory = number
            })
          })
          service = object({
            port = string
            proxy = object({
              expose = list(
                object({
                  path          = string
                  protocol      = string
                  local_port    = number
                  listener_port = string
                })
              )
              upstreams = list(
                object({
                  name = string
                  port = number
                })
              )
            })
          })
        })
      })
    })
  )
  default = [
    {
      name         = "vmagent"
      port         = "8429"
      tags         = []
      provider     = "consul"
      address      = null
      address_mode = "auto"
      address      = null
      address_mode = "auto"
      checks = [
        {
          address_mode    = null
          args            = null
          restart         = null
          command         = null
          interval        = "30s"
          method          = null
          body            = null
          name            = null
          path            = "/-/healthy"
          expose          = false
          port            = "service-check"
          protocol        = "http"
          task            = null
          timeout         = "5s"
          type            = "http"
          tls_server_name = null
          tls_skip_verify = false
          on_update       = null
          headers         = null
        }
      ]
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "envoy-proxy"
            proxy = {
              expose = [
                {
                  path          = "/-/healthy"
                  protocol      = "http"
                  local_port    = 8429
                  listener_port = "service-check"
                }
              ]
              config = {}
              upstreams = [
                {
                  name = "victoria-metrics"
                  port = 8428
                }
              ]
            }
          }
        }
      }
    }
  ]
}

variable "vault" {
  type = object({
    env           = bool
    role          = string
    change_mode   = string
    change_signal = string
  })
  default = null
}

variable "consul" {
  type    = object({})
  default = null
}

variable "docker_config" {
  type = object({
    image      = string
    entrypoint = list(string)
    args       = list(string)
    volumes    = list(string)
    privileged = bool
    devices = list(
      object({
        host_path          = string
        container_path     = string
        cgroup_permissions = string
      })
    )
  })
  default = {
    image      = "victoriametrics/vmagent:latest"
    entrypoint = null
    args       = ["-promscrape.config=$${NOMAD_TASK_DIR}/vmagent.yaml", "-remoteWrite.url=http://127.0.0.1:8428/api/v1/write"]
    volumes    = []
    privileged = false
    devices    = []
  }
}

variable "resources" {
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 50,
    memory = 192
  }
}

variable "templates" {
  type = list(
    object({
      data          = string
      destination   = string
      change_mode   = string
      change_signal = string
      env           = bool
      uid           = number
      gid           = number
      perms         = string
    })
  )
  default = [
    {
      data          = <<EOH
---
global:
  scrape_interval: 15s
      EOH
      destination   = "$${NOMAD_TASK_DIR}/vmagent.yaml"
      change_mode   = "restart"
      change_signal = null
      env           = false
      perms         = null
      uid           = -1
      gid           = -1
    }
  ]
}

variable "volumes" {
  type = list(
    object({
      name            = string
      type            = string
      source          = string
      read_only       = bool
      access_mode     = string
      attachment_mode = string
    })
  )
  default = []
}

variable "volume_mounts" {
  type = list(
    object({
      volume        = string
      destination   = string
      read_only     = bool
      selinux_label = string
    })
  )
  default = []
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "artifacts" {
  type = list(
    object({
      source      = string
      destination = string
      mode        = string
    })
  )
  default = []
}

variable "restart" {
  type = object({
    attempts         = number
    delay            = string
    interval         = string
    mode             = string
    render_templates = bool
  })
  default = {
    mode             = "delay"
    delay            = "15s"
    interval         = "10m"
    attempts         = 3
    render_templates = false
  }
}

variable "identities" {
  type = list(
    object({
      name          = string
      env           = bool
      file          = bool
      audience      = list(string)
      change_mode   = string
      change_signal = string
    })
  )
  default = []
}

variable "count" {
  type    = number
  default = 1
}
