# terraform/


- `local/` is the **lab server**. an ubuntu container on your own machine made with the docker provider, ssh on `localhost:2222`.
  used as the offline test target for the ansible playbook
- `cloud/` is the **real vm** at ntnu openstack. key pair, security group (only 22 and 5000) and an ubuntu vm with a public 129.241.101.x address

`terraform init` makes `.terraform/` and a state file in each module,
both are ignored by the `.gitignore` in the repo root.
keep it that way since state files can have credentials in plain text
