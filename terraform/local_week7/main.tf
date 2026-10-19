# The lab server - the week 6 module with the WEEK 7 edits on top (every one
# is marked "week 7"): systemd as PID 1 in server/Dockerfile, and `privileged`
# plus two volumes in the container block below. Four building blocks, in the
# order Terraform has to build them; the references between blocks are what
# give it that order.
#
# Every resource has TWO names: the TYPE (docker_image) and the LABEL ("server").
# Other blocks refer to it as TYPE.LABEL.attribute.

# --- 1. The image ------------------------------------------------------------
# Built from server/Dockerfile. `triggers` holds a hash of the Dockerfile, so
# a changed file means a rebuilt image - without it Terraform keeps the old
# image forever.
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
# The server's own bridge network - a cloud's private network + security group.
resource "docker_network" "lab" {
  name = "lab-net"
}

# --- 3. The server -----------------------------------------------------------
# `ports` is what the outside can reach, and where (a cloud's security group
# plus floating IP). Changing `name` or `ports` forces -/+ (replace); changing
# `restart` is ~ (in place). The plan tells you which, every time.
resource "docker_container" "server" {
  name     = var.server_name
  hostname = var.server_name              # so the prompt reads ubuntu@lab-server
  image    = docker_image.server.image_id # the ID, not .name: it changes with the Dockerfile, so the server follows the image
  restart  = "unless-stopped"

  # week 7: systemd inside needs the same privileges a VM has over itself (cgroups,
  # mounts, its own Docker daemon later). A real VM needs no such flag.
  privileged = true

  ports {
    internal = 22
    external = var.ssh_port
  }

  networks_advanced {
    name = docker_network.lab.name
  }

  # week 7: the Docker daemon INSIDE the server stores its images here. That
  # storage cannot sit on top of the server's own container filesystem, so it
  # gets two volumes of its own - the same thing a VM has in its disk.
  volumes {
    container_path = "/var/lib/docker"
  }
  volumes {
    container_path = "/var/lib/containerd"
  }

  # --- 4. The key ------------------------------------------------------------
  # How you get in. At creation Terraform reads your PUBLIC key (`pathexpand`
  # turns ~ into your home directory, `file` reads the one line of text) and
  # writes it into the server as the file sshd checks on every login. Only the
  # public half travels; the private key never leaves ~/.ssh on your machine.
  # A cloud does the same through cloud-init when you attach a "key pair".
  #
  # Green apply but "Permission denied (publickey)"? Terraform cannot know the
  # key is wrong - check: this block exists, `file` is exactly this path, the
  # .pub matches the private key you offer, and a non-default key name gets
  # `ssh -i ~/.ssh/<private key>`.
  upload {
    file    = "/home/ubuntu/.ssh/authorized_keys"
    content = file(pathexpand(var.ssh_public_key_path))
  }
}
