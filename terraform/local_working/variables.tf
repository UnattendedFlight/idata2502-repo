# Input variables for the week 6 lab server.
#
# A variable is the one place a personal value lives - the structure in main.tf
# never changes, only these do.

# --- The key ------------------------------------------------------------------
# SSH login works with a KEY PAIR, made by `ssh-keygen -t ed25519`:
#   ~/.ssh/id_ed25519       the PRIVATE key - stays on your machine, is never
#                           copied anywhere, never committed, never pasted
#   ~/.ssh/id_ed25519.pub   the PUBLIC key  - one line of text, safe to share;
#                           anyone holding it can only *verify* you, not *be* you
#
# This variable points at the PUBLIC key. Terraform reads that one line and
# writes it into the server as /home/ubuntu/.ssh/authorized_keys (the `upload`
# block in main.tf). When you run `ssh ubuntu@localhost`, your ssh client proves
# it holds the matching private key, and the server lets you in - no password
# exists.
#
# No key at all (`ls ~/.ssh/*.pub` says "No such file or directory")? Make one:
#   mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
# (`-N ''` = no passphrase, fine for a lab key; `mkdir` because a fresh machine
# has no ~/.ssh yet. If it says "already exists. Overwrite?", answer n.)
#
# Named your key something else (`ls ~/.ssh/*.pub` shows the truth)?
#   1. Point this default at YOUR .pub file, or pass
#      `-var ssh_public_key_path=~/.ssh/mykey.pub` to plan/apply.
#   2. ssh only offers keys with default names (id_ed25519, id_rsa, ...) by
#      itself - for any other name log in with
#      `ssh -i ~/.ssh/mykey -p 2222 ubuntu@localhost`  (the PRIVATE file, no .pub)
#      or "Permission denied (publickey)" follows even though Terraform did
#      everything right.
variable "ssh_public_key_path" {
  description = "Path to your PUBLIC SSH key (.pub) - Terraform copies its content onto the server; the private key stays with you"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_port" {
  description = "Port on your machine that forwards to the server's SSH (22)"
  type        = number
  default     = 2222
}

variable "server_name" {
  description = "Name (and hostname) of the container that plays the server"
  type        = string
  default     = "lab-server"
}
