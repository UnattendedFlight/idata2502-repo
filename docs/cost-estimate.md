# Cost estimate

what this setup would cost per month outside ntnus openstack:
one vm running the app, redis and the monitoring stack (prometheus, loki, alloy, grafana),
with 20 GB of disk, one public IPv4 address and 50 GB of outbound traffic, running for th whole month (730 hours).

prices are list prices excluding mva, checked on 26.11.26.
AWS figures come from the AWS price list `eu-north-1` (stockholm), linux, shared tenancy, published 26.11.26/25.
Hetzner prices are from hetzner.com/cloud.

openstack vm is `gx3.1c1r` (1 vcpu, 1 GB ram) with 1 GB of swap.
`t3.micro` (2 vCPU burstable, 1 GB) matches that, and `t3.small` (2 vCPU, 2 GB) is the size more preferrred for the monitoring stack.

## AWS, eu-north-1

| Item | Unit price | t3.micro on demand | t3.micro 1-yr no upfront | t3.small on demand | t3.small 1 year no upfront |
|---|---|---:|---:|---:|---:|
| Instance, 730 h | micro $0.0108 / $0.0068 per h. small $0.0216 / $0.0136 per h | $7.88 | $4.96 | $15.77 | $9.93 |
| EBS gp3, 20 GB | $0.0836 per GB-month (3000 IOPS, 125 MB/s included) | $1.67 | $1.67 | $1.67 | $1.67 |
| Public IPv4, 730 h | $0.005 per h | $3.65 | $3.65 | $3.65 | $3.65 |
| Egress, 50 GB | $0.09 per GB after 100 GB/month free | $0.00 | $0.00 | $0.00 | $0.00 |
| **Total per month (USD)** | | **$13.21** | **$10.29** | **$21.09** | **$15.25** |
| **Total per month (NOK)** | | **~130 kr** | **~100 kr** | **~200 kr** | **~150 kr** |
| per year (USD) | | $158 | $123 | $253 | $183 |

"1 year no upfront" is a 1 year Standard Reserved Instance with no upfront payment.
a 1 year EC2 Instance Savings Plan has the same rate. A Compute Savings Plan is more flexible but saves less ($0.0088 and $0.0177 per hour).

## Hetzner Cloud, 2 vCPU / 4 GB

| Plan | Spec | Per month (EUR) | Per month (NOK) | Included |
|---|---|---:|---:|---|
| CX23 | 2 vCPU (shared), 4 GB, 40 GB NVMe | €5.99 | ~60 kr | IPv4, 20 TB traffic |
| CPX22 (regular), Helsinki | 2 vCPU (AMD, shared), 4 GB, 80 GB NVMe | €16.99 | ~180 kr | IPv4, 20 TB traffic |
| CPX22, Nuremberg | same | €19.99 | ~200 kr | IPv4, 20 TB traffic |

the CX23 is listed but **not available to order** today (26.11.26)
CPX22 is the cheapest 2 vCPU / 4 GB plan you can actually buy.
Hetzner raised prices on 1 April and 15 June 2026 (existing servers kept their price),
then cut Helsinki prices by 15% from 10 November 2026. disk, IPv4 and 50 GB of traffic are all included in the plan price.

## Summary

- **the biggest item is the instance:** 75% of the `t3.small` ondemand bill ($15.77 of $21.09), and 60% for `t3.micro`.
  the second biggest is the public IPv4 address at $3.65 a month.
  that costs almost half as much as a `t3.micro` itself, and it is paid whether the vm is running or not.
- **egress free:** 50 GB fits inside AWS 100 GB/month free allowance,
  which is shared across all AWS services and regions.
  without the  allowance it would cost $4.50
- **the 1 year commitment saves 37%** on the instance price for both sizes ($0.0216 -> $0.0136 per hour for `t3.small`).
  the whole bill falls by 27.7% (`t3.small`) and 22.1% (`t3.micro`), because disk and IPv4 are not discounted.
  the trade off, is paying for a full year even if the course project ends after one semester
- **hetzner gives more for less:** a CPX22 (~180 kr) has twice the RAM of a `t3.small` for about ~90% of its on demand price (~200 kr),
  with no bill for IPv4 or traffic. a CX23 if it can be ordered again, costs half of a `t3.micro`.
- **exchange rates:** Norges Bank's mid rates for 25 November 2026, the latest
  published: **1 USD = 9.8562 NOK** and **1 EUR = 10.7778 NOK**. NOK figures are rounded to whole tens and exclude 25% MVA.
- **caveat:** `t3` instances are burstable. above the baseline CPU they use credits, and in the default "unlimited" mode a vm that stays busy pays extra.
  a mostly idle app with a montoring stack should stay below the baseline.
