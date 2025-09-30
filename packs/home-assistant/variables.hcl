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
    mode  = "host"
    ports = []
    dns   = null
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
  default = []
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

variable "qemu_config" {
  type = object({
    image_path        = string
    drive_interface   = string
    accelerator       = string
    graceful_shutdown = bool
    guest_agent       = bool
    port_map          = map(number)
    args              = list(string)
  })

  default = {
    image_path        = "/var/lib/nomad/qemu_images/home-assistant/image.qcow2"
    drive_interface   = "ide"
    accelerator       = "kvm"
    graceful_shutdown = true
    guest_agent       = false
    port_map          = {}
    args = [
      # UEFI
      "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd",
      "-drive", "if=pflash,format=raw,file=/var/lib/nomad/qemu_images/home-assistant/OVMF_VARS_4M.fd",

      # Network (since Nomad one is broken https://github.com/hashicorp/nomad/issues/10033)
      "-netdev", "bridge,id=net0,br=br0",
      "-device", "virtio-net,netdev=net0",

      # QEMU agent (because guest_agent breaks the network)
      "-device", "virtio-serial",
      "-chardev", "socket,path=/var/lib/nomad/alloc/$${NOMAD_ALLOC_ID}/$${NOMAD_TASK_NAME}/qa.sock,server=on,wait=off,id=qga0",
      "-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0",
    ]
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

variable "resources" {
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 400
    memory = 2048
  }
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
