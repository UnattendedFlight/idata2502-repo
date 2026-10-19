# Main resources - you write these during the week 6 lab.
#
# Goal: one "server" you can SSH into, built and owned by Terraform. Today it
# is a container on your own machine; the four building blocks mirror what a
# cloud gives you (image / network / instance / key pair).
#
# Work one block at a time and run `terraform plan` before moving on - the
# count grows 1 to add, 2 to add, 3 to add (the key lives inside block 3, so
# it adds nothing). Look the attribute names up in the provider docs:
# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
#
# Every resource has TWO names: the TYPE (docker_image) and your LABEL
# ("server"). Other blocks refer to it as  TYPE.LABEL.attribute  - so keep the
# labels below exactly, or the references in the slides will not match yours.

# --- 1. The image ------------------------------------------------------------
# Build server/Dockerfile (Ubuntu + sshd + python3, keys only) into an image.
# `triggers` makes Terraform rebuild when the Dockerfile changes.
# Resource type: docker_image  (with a `build { context = ... }` block)
#
# resource "docker_image" "server" {
#   name = "lab-server:latest"
#   build {
#     context = "${path.module}/server"
#   }
#   triggers = {
#     dockerfile = filesha256("${path.module}/server/Dockerfile")
#   }
# }
#
# `path.module` is the folder this file is in, so the paths hold wherever the
# repo is cloned. `filesha256` is a fingerprint of the Dockerfile: a new
# fingerprint means a new image, and a rebuilt server - that is all `triggers` is.

# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image
resource "docker_image" "server" {
  name = "lab-server:latest"
  build {
    context = "${path.module}/server"
  }
  triggers = {
    dockerfile = filesha256("${path.module}/server/Dockerfile")
  }
}


# --- 2. The network ----------------------------------------------------------
# A network of its own, like a cloud's private network + security group.
# Resource type: docker_network
#
# resource "docker_network" "lab" {
#   name = ...
# }

resource "docker_network" "lab" {
  name = "lab-net"
}


# --- 3. The server -----------------------------------------------------------
# Run the image as a container: name and hostname from var.server_name, port
# var.ssh_port -> 22, attached to the network, restart = "unless-stopped".
# Resource type: docker_container  (with `ports` and `networks_advanced` blocks)
#
# The two references that tie the blocks together:
#   image = docker_image.server.image_id     <- the ID, not .name: the ID changes
#                                               when the Dockerfile changes, so a
#                                               rebuilt image gives a rebuilt server
#   networks_advanced { name = docker_network.lab.name }
#
# resource "docker_container" "server" {
#   ...
# }

# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container
resource "docker_container" "server" {
  name     = var.server_name
  hostname = var.server_name
  image    = docker_image.server.image_id
  restart  = "unless-stopped"

  ports {
    internal = 22
    external = var.ssh_port # 2222
  }

  networks_advanced {
    name = docker_network.lab.name # named, so lab-net
  }

  # public key only
  upload {
    file    = "/home/ubuntu/.ssh/authorized_keys" # uploads the id_ed25519.pub file to authorized keys for passwordless login
    content = file(pathexpand(var.ssh_public_key_path)) # reads the id_ed25519.pub file from the path in the variable
  }
}


# --- 4. The key --------------------------------------------------------------
# Inside the docker_container block. This is how you get in - read it twice.
#
#   upload {
#     file    = "/home/ubuntu/.ssh/authorized_keys"
#     content = file(pathexpand(var.ssh_public_key_path))
#   }
#
# What happens: at creation Terraform reads your PUBLIC key from the path in
# the variable (`pathexpand` turns ~ into your home directory, `file` reads the
# one line of text) and writes it into the server as the file sshd checks on
# every login attempt. Only the public half travels; the private key never
# leaves ~/.ssh on your machine. This is exactly what a cloud does with
# cloud-init when you attach a "key pair" to a VM.
#
# Symptoms if something is off (apply is still green - Terraform cannot know):
#   Permission denied (publickey)  -> block missing, wrong `file` path, the .pub
#                                     does not match the private key you offer,
#                                     or the key has a non-default name (use -i)
#   no file exists at ...pub       -> at plan time: the variable points at a
#                                     file that is not there (`ls ~/.ssh/*.pub`)
