# terraform/cloud/

the **vm** at ntnu openstack (skyhigh, region TRD1).
a key pair, a security group that only opens 22 and 5000, and an ubuntu vm on `idata2502-exposed`, which gives it a public 129.241.101.x address

```bash
cp terraform.tfvars.example terraform.tfvars   # then put your ntnu username in
terraform init
make cloud-plan / make cloud-apply / make cloud-destroy   # from the repo root
```

## before plan and apply

needs credential from openstack, the `~/.config/openstack/clouds.yaml`

**dont** puit it in this folder or the repo.
the root `.gitignore` catches `clouds*.yaml` just in case. same goes for `terraform.tfvars` and the state files

## notes

- **vpn:** `plan`, `apply` and `destroy` need ntnu vpn from home, the openstack api only answers inside ntnu.
  ssh to the vm and the app work without it
- **state:** the state file here is the only record of what you made in shared project.
  apply from one machine, dont delete the folder, and run `terraform destroy` when youre done with a vm
