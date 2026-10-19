# local_skeleton/

The **starting point** for the week 6 lab. Copy it to `terraform/local/` and
work there:

```bash
cp -r terraform/local_skeleton terraform/local
cd terraform/local
terraform init
```

First, a key. `ls ~/.ssh/*.pub` must show a `.pub` file. If it says "No such
file or directory":

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
```

If it shows a file with another name, point `ssh_public_key_path` in
`variables.tf` at it and log in with `ssh -i ~/.ssh/<private key>`.

`providers.tf`, `variables.tf` and `server/Dockerfile` are finished. `main.tf`
has the four resource blocks as TODO comments and `outputs.tf` has one - those
are yours to write, one block at a time with `terraform plan` between each.

Stuck, or done and want to compare? The finished version is in
`../local_working/`. Never `apply` both at once: they build the same server on
the same port.
