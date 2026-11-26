# terraform/local/

the **local lab server**

a ubuntu container with ssh on `localhost:2222`.
its the offline test target for the ansible playbook

```bash
make apply           # terraform -chdir=terraform/local apply
make ansible-local   # site.yml against ansible/inventory.local.ini
```

it installs `~/.ssh/id_ed25519.pub` as the key (`ssh_public_key_path` in `variables.tf`).
the state file stays here and is gitignored
