# Terraform tells you the address of the house it built. Week 7 puts this into
# the Ansible inventory.
#
# Key with a non-default name? Add `-i ~/.ssh/<your private key>` in front of -p.
output "ssh_command" {
  value = "ssh -p ${var.ssh_port} ubuntu@localhost"
}
