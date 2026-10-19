# Provider configuration for the lab server (weeks 6-7).
#
# Today the "cloud" is your own Docker daemon: the Docker provider talks to it
# over the default socket, so there are no credentials and no account. Against
# a real cloud only this block and the resource types change - the loop, the
# state and the plan stay the same.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {} # local Docker daemon, default socket (WSL: Docker Engine inside the distro)
