# ansible/

Your Ansible inventory and playbooks belong here.

The inventory names one host, `lab-server`, in the group `app`. In week 7 its
address is your local lab server (`127.0.0.1`, port `2222`); in week 8 you
change that one line to the real VM's address and run the same playbook again.

An inventory with real server addresses is not something you want in a public
repository - `inventory.ini` is already excluded by the `.gitignore` in the
repository root. If you want a version others can copy, commit an
`inventory.ini.example` with the addresses left blank.
