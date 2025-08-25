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
        name         = "connect-proxy-minio-api"
        to           = -1
        static       = 0
        host_network = "connect"
      },
      {
        name         = "connect-proxy-minio-console"
        to           = -1
        static       = 0
        host_network = "connect"
      },
      {
        name         = "service-check-minio-api"
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
      name     = "minio-api"
      port     = "9000"
      tags     = []
      provider = "consul"
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
          path            = "/minio/health/live"
          expose          = false
          port            = "service-check-minio-api"
          protocol        = "http"
          task            = null
          timeout         = "5s"
          type            = "http"
          tls_server_name = null
          tls_skip_verify = false
          headers         = null
        }
      ]
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "connect-proxy-minio-api"
            proxy = {
              expose = [
                {
                  path          = "/minio/health/live"
                  protocol      = "http"
                  local_port    = 9000
                  listener_port = "service-check-minio-api"
                }
              ]
              config    = {}
              upstreams = []
            }
          }
        }
      }
    },
    {
      name     = "minio-console"
      port     = "9001"
      tags     = []
      provider = "consul"
      checks   = []
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "connect-proxy-minio-console"
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
    image      = "quay.io/minio/minio:latest"
    entrypoint = null
    args = [
      "server", "/data",
      "--console-address", ":9001",
    ]
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

variable "resources" {
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 256,
    memory = 1024
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
  default = [
    {
      type            = "host"
      name            = "data"
      source          = "minio-data"
      read_only       = false
      access_mode     = "single-node-single-writer"
      attachment_mode = "file-system"
    }
  ]
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
  default = [
    {
      volume        = "data"
      destination   = "/data"
      read_only     = false
      selinux_label = null
    }
  ]
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
