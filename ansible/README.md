# ansible/

`site.yml` configures a fresh ubuntu host to run the app

| Inventory | Target | How |
|---|---|---|
| `inventory.ini` (gitignored) | the vm at ntnu openstack | `make inventory` writes it from `inventory.ini.example` and the terraform output. `make ansible` runs the playbook |
| `inventory.local.ini` | the local lab server from `terraform/local` (port 2222) | `make apply`, then `make ansible-local` |

the local lab server is a container and not a vm. the swap tasks and the `ssh` restart handler need a real machine and may fail there
