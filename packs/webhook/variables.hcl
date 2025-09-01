# Copyright (c) Kasefuchs
# SPDX-License-Identifier: MIT

variable "job_name" {
  type    = string
  default = ""
}

variable "job_type" {
  type    = string
  default = "service"
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
      }
    ]
    dns = null
  }
}

variable "services" {
  type = list(
    object({
      name     = string
      port     = string
      tags     = list(string)
      provider = string
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
      name     = "webhook"
      port     = "8080"
      tags     = []
      provider = "consul"
      checks   = []
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "envoy-proxy"
            proxy = {
              expose    = []
              config    = {}
              upstreams = []
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
  })
  default = {
    image      = "ghcr.io/krabiworld/webhook:latest"
    entrypoint = null
    args       = null
    volumes    = []
    privileged = false
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
  default = []
}

variable "environment" {
  type = map(string)
  default = {
    LOG_LEVEL         = "info"
    ADDR              = "0.0.0.0:8080"
    SECRET            = "random-string"
    HAPPY_EMOJI       = ":tada:"
    SUCCESS_EMOJI     = ":ok:"
    FAILURE_EMOJI     = ":boom:"
    IGNORED_WORKFLOWS = "CodeQL,Automatic Dependency Submission,Dependabot Updates"
  }
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

variable "resources" {
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 16,
    memory = 64
  }
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

variable "restart" {
  type = object({
    attempts         = number
    delay            = string
    interval         = string
    mode             = string
    render_templates = bool
  })
  default = {
    mode             = "fail"
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
