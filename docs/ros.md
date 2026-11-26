# Risk assessment (ROS)

covers the app, the ci/cd pipeline, the vm at ntnu openstack and the monitoring stack, as they are in this repo on 26.11.26

probability: **low** (not expected while the project runs), **medium** (could happen), **high** (expected, or already happened).
consequence: **low** (annoying, nothing exposed), **medium** (downtime or lost data, fixable from code), **high** (someone gets secrets, the vm or the image, or stuff that cant just be rebuilt from code)

"before" is the rating without the mitigations, "done" is what is already in place, "after" is the rating with them. "todo" is what could be added later

## Risks

| ID | Risk | Before (P / C) | Done | After (P / C) | Todo |
|---|---|---|---|---|---|
| R1 | **deploy key leaks** (`VM_SSH_KEY`). `ubuntu` has passwordless sudo and is in the `docker` group, so the key is basically root on the vm | Medium / High | own key only for github actions, only stored as a github secret. revoking it is one ansible task (`authorized_key ... state: absent`) and a new key. password and root login are off (`10-hardening.conf`) | Low / High | separate `deploy` user without sudo, and `command=`/`from=` on the key in `authorized_keys` |
| R2 | **a third party action gets compromised.** a moved tag could run someone elses code with the deploy key, secrets or a token that can push images | Medium / High | every action (`actions/checkout`, `docker/login-action`, `appleboy/ssh-action`, `appleboy/scp-action`, `aquasecurity/trivy-action`) is pinned to a full commit sha. jobs get least privilege `permissions:` (deploy only has `packages: read`). dependabot version updates (`.github/dependabot.yml`) keep the pinned shas updated through PRs | Low / High | - |
| R3 | **no tls on :5000.** plain http, so the `X-API-Key` header for `POST /reset` can be read or replayed by anyone in between | Medium / Medium | only 22 and 5000 are open, grafana is not exposed. `/reset` is the only endpoint with a key and a leaked key only resets a counter | Medium / Medium | reverse proxy (caddy) with a lets encrypt cert on 443 under a name in `idata2502-h26.iaas.ntnu.no`, and close 5000 |
| R4 | **redis data is lost**, there is no backup | High / Low | named volume (`redis-data`) keeps the data across deploys and restarts | Medium / Low | scheduled `BGSAVE` and copy the rdb file off the vm. destroying the vm still loses it, but its a visit counter so thats accepted |
| R5 | **the vm goes down** (crash, openstack problem, quota, or the course project getting deleted 27.11.26). no HA, so the app is down until someone fixes it | Medium / High | everything is code: `make rebuild` + `gh workflow run main.yml` gets vm, config and deploy back in about ten minutes. `restart: unless-stopped` on every service and docker on at boot. the `up{job="app"}` panel shows it | Medium / Medium | grafana alert on `up{job="app"} == 0`, and an external uptime check since grafana dies with the vm. a second vm behind a load balancer if it ever matters |
| R6 | **cve in the base image or dependencies.** already happened: trivy found three HIGH (CVE-2026-23949, CVE-2026-124851, CVE-2026-24049) | High / Medium | trivy scans every build and fails it on fixable HIGH/CRITICAL. base bumped to `python:3.12-slim` plus an `apt-get upgrade` layer. container runs as non root (uid 10001). dependabot alerts are on, and `.github/dependabot.yml` opens weekly PRs for the pip packages in `app/` | Medium / Medium | weekly scan of the running `latest` image. a cve published after the last build isnt seen until the next build |
| R7 | **terraform state is lost** (`terraform/cloud/terraform.tfstate` only lives on one laptop). terraform forgets the vm, key pair and security group, they become orphans in the shared project and a new `apply` collides on names | Low / High | state is gitignored (can hold secrets) and the readme says to apply from one machine. all resource names come from `server_name`, so orphans are easy to find and delete in horizon, or `terraform import` back | Low / Medium | remote backend (openstack swift / s3) with locking and versioning |
| R8 | **deploy job doesnt check the host key.** `ssh-action`/`scp-action` run without `fingerprint:`, so a mitm between the runner and the vm would get the secrets written to `.env` (`API_KEY`, `GRAFANA_PASSWORD`) and the short lived ghcr token. the private key itself is not exposed | Low / High | the registry token is the jobs own `GITHUB_TOKEN`, read only and expires with the job | Low / High | store the vms host key fingerprint (`ssh-keyscan` + `ssh-keygen -lf`) as a secret and pass it as `fingerprint:` to both actions. `make host-secret` could set it next to `VM_HOST` |
| R9 | **`/metrics` and `/health` are public on :5000.** anyone can read the route names, request counts, error rates and latency from `/metrics`, and the version, commit and branch from `/health`. useful for picking a target or timing an attack | High / Low | metrics are labelled by route pattern (`/hello/<name>`), not the raw url, so no user input or ids end up in them. no secrets in either endpoint | High / Low | serve `/metrics` on a second port that is only on the compose network (prometheus scrapes it there, nothing publishes it), or block `/metrics` in the reverse proxy from R3. trim `/health` to `{"status": "ok"}` publicly. the `/` page also prints version, commit and build time, so that would need trimming too |

## Matrix

before, without the mitigations:

|  | **Probability: Low** | **Medium** | **High** |
|---|---|---|---|
| **Consequence: High** | R7 state file, R8 host key | R1 deploy key, R2 action, R5 single vm | |
| **Medium** | | R3 no tls | R6 cve |
| **Low** | | | R4 redis data, R9 metrics |

after, with the done mitigations in place:

|  | **Probability: Low** | **Medium** | **High** |
|---|---|---|---|
| **Consequence: High** | R1 deploy key, R2 action, R8 host key | | |
| **Medium** | R7 state file | R3 no tls, R5 single vm, R6 cve | |
| **Low** | | R4 redis data | R9 metrics |

nothing high consequence is above low probability anymore. R3, R8 and R9 dont move, the done items there are small and the real fix is still in todo. R9 is the only high probability risk left (the endpoints are public, so someone will read them), but the consequence is low

## What to do next

- **R8 host key first:** its a few lines of yaml and closes a high consequence risk
- **R1 deploy user:** one more ansible task, and the key stops being root on the vm
- **R3 tls:** the biggest piece of work, but also the most visible gap for an actual user
- **R9 /metrics:** small change (second port or proxy rule) and it removes the last high probability risk
- R2 is mostly covered now that actions are pinned and dependabot keeps them updated
