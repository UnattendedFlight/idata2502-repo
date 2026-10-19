# local_week7/

The lab server from week 6 with **two edits** on top - the version the week 7
lab (Ansible) runs against. Week 6's `local_working/` runs `sshd` directly as
the server's first process, which is enough to log in but means the server
cannot run *services*. This module boots **systemd** instead, exactly like a
VM, so Ansible can install Docker and actually start it.

The two edits, marked `week 7` in the files - make the same ones in **your**
`terraform/local/`:

1. `server/Dockerfile` - install `systemd systemd-sysv`, `systemctl enable ssh`,
   add `STOPSIGNAL SIGRTMIN+3`, and change the last line to
   `CMD ["/sbin/init"]`.
2. `main.tf`, in the container block - `privileged = true`, and two `volumes`
   blocks for `/var/lib/docker` and `/var/lib/containerd` (where the Docker
   daemon *inside* the server will keep its images).

Then `terraform plan` shows the server being **replaced** (`-/+`) - a changed
Dockerfile and a changed container setting both force that - and
`terraform apply` rebuilds it in about a minute. New server, new host key:
`ssh-keygen -R "[localhost]:2222"` before you log in.

Or run this module as it is when you are stuck or out of time:

```bash
cd terraform/local_week7
terraform init
terraform apply     # then: ssh -p 2222 ubuntu@localhost
```

Never `apply` this and `terraform/local/` (or `local_working/`) at the same
time - same server, same port, same names. `terraform destroy` one before you
`apply` the other.
