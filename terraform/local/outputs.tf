# Output values - write this in the week 6 lab, once the container exists.
#
# Goal: after `terraform apply`, Terraform prints how to reach the server.
# In week 7 ansible/inventory.ini points at the same address and port.
#
# Key with a non-default name? The output is still right - add
# `-i ~/.ssh/<your private key>` in front of -p when you use it.

# https://developer.hashicorp.com/terraform/language/values/outputs
output "ssh_command" {
  value = "ssh -p ${var.ssh_port} ubuntu@localhost"
}
