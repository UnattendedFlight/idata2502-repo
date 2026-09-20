# terraform/

Your Terraform code belongs here, as two root modules side by side:

- `local/` - week 6: the **lab server**, a container on your own machine built
  with the Docker provider (plus `local/server/Dockerfile`, the image it is
  built from). No cloud account needed.
- `cloud/` - week 8: the **real VM** at the course's cloud provider. Same
  building blocks, different provider - the provider and its values are
  announced in class.

Nothing in this folder is generated for you - `terraform init` will create
`.terraform/` and a state file in each module, and those are already excluded
by the `.gitignore` in the repository root. Keep them excluded: state files can
contain credentials in plain text.
