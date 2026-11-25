# Main resources - you write these during the week 9 lab.
#
# Goal: a real VM at NTNU OpenStack you can SSH into from anywhere - the week 6
# lab server's building blocks with different nouns: key pair, security group,
# VM. The public IP needs no block of its own: the VM sits on a network of
# public addresses (idata2502-exposed) and gets one when it boots.
#
# How the blocks fit together - each line is one reference you write:
#   rule 22, rule 5000  ->  group     security_group_id = <group>.id
#   group               ->  VM        security_groups   = [<group>.name]
#   key pair            ->  VM        key_pair          = <key pair>.name
#   VM                  ->  outputs   access_ip_v4 (already in outputs.tf)
#
# Work one block at a time and run `terraform plan` before moving on. Look the
# attribute names up in the provider docs:
# https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs
#
# Keep the LABELS below ("key", "server") - outputs.tf and the optional DNS
# step on the slides refer to them.
#
# The project is shared: every name comes from var.server_name, so nothing
# you create collides with a classmate's.

# --- 1. The key pair ---------------------------------------------------------
# Your PUBLIC key, uploaded to OpenStack. cloud-init writes it into
# /home/ubuntu/.ssh/authorized_keys when the VM boots - week 6's `upload`.
# Resource type: openstack_compute_keypair_v2
#
# resource "openstack_compute_keypair_v2" "key" {
#   name       = "${var.server_name}-key"
#   public_key = ...   <- the same file(pathexpand(...)) as in week 6
# }

resource "openstack_compute_keypair_v2" "key" {
  name       = "${var.server_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}


# --- 2. The security group ---------------------------------------------------
# A cloud is closed until you open it. Open tcp 22 (you, Ansible, the deploy
# job) and 5000 (the app), both from 0.0.0.0/0 - GitHub's runners are not on
# campus. Login is key-only.
# Resource types: openstack_networking_secgroup_v2 (the group, named
# "${var.server_name}-sg") and one openstack_networking_secgroup_rule_v2 per
# port: direction "ingress", ethertype "IPv4", protocol "tcp",
# port_range_min/max, remote_ip_prefix and security_group_id.
# Two links hold it together:
#   each rule:  security_group_id = <the group>.id        rule -> group, by id
#   the VM:     security_groups   = [<the group>.name]    VM -> group, by name
# The lab slide "block 2 up close" writes one rule out in full.
#
# resource "openstack_networking_secgroup_v2" "server" {
#   ...
# }

resource "openstack_networking_secgroup_v2" "server" {
  name        = "${var.server_name}-sg"
  description = "SSH and the app only"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.server.id
}

resource "openstack_networking_secgroup_rule_v2" "app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5000
  port_range_max    = 5000
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.server.id
}


# --- 3. The VM ---------------------------------------------------------------
# Image, flavor and network by name from the variables, plus blocks 1-2:
#   key_pair        = openstack_compute_keypair_v2.key.name
#   security_groups = [ ...the group's name... ]
#   network { name = var.network_name }
# The network decides the address: on idata2502-exposed (the default) the VM
# gets a public 129.241.101.x, read back as access_ip_v4. On any other network
# it gets a private address that GitHub's runners cannot reach.
# Resource type: openstack_compute_instance_v2
#
# resource "openstack_compute_instance_v2" "server" {
#   name = var.server_name
#   ...
# }

resource "openstack_compute_instance_v2" "server" {
  name            = var.server_name
  image_name      = var.image_name
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.key.name
  security_groups = [openstack_networking_secgroup_v2.server.name]

  network {
    name = var.network_name
  }
}
