# cloud_skeleton/

The **starting point** for the week 9 lab: the real VM at NTNU OpenStack.
Copy it to `terraform/cloud/` and work there:

```bash
cp -r terraform/cloud_skeleton terraform/cloud
cd terraform/cloud
cp terraform.tfvars.example terraform.tfvars   # then put your NTNU username in
terraform init
```

`providers.tf`, `variables.tf` and `outputs.tf` are finished. `main.tf` has
the three blocks as TODO comments - those are yours to write, one block at a
time with `terraform plan` between each. The week 6 rhythm, with a different
provider. `outputs.tf` is commented out because it points at the VM in block
3: uncomment it once block 3 is written.

Before `plan` and `apply` work you need `~/.config/openstack/clouds.yaml` - the
application credential from the lab's part 0, made in project `IDATA2502_H26`,
region `TRD1`. It **never** goes in this folder or the repo; the `.gitignore`
in the repository root catches `clouds*.yaml` as a safety net, but do not
rely on it. Same for `terraform.tfvars` and the state files.

Working from home? `plan`, `apply` and `destroy` need **VPN** - the OpenStack
API answers only inside NTNU. SSH to the VM and the app work without it.

The state file in `terraform/cloud/` is the only record of what you made in a
shared project. Apply from one machine, do not delete the folder, and
`terraform destroy` when you are done with a VM.
