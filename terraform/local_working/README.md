# local_working/

The **finished** week 6 module - the answer to `../local_skeleton/`. Use it to
compare when you are done, or to get unstuck: read the block you are missing,
understand it, then write it in your own `terraform/local/`.

It also runs as it is, if you need a working server and are out of time:

```bash
cd terraform/local_working
terraform init
terraform apply     # then: ssh -p 2222 ubuntu@localhost
```

Never `apply` this and `terraform/local/` at the same time - they build the
same server, on the same port, with the same names. `terraform destroy` one
before you `apply` the other.
