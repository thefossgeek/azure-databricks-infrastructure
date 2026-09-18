# azure-databricks-infrastructure

Terragrunt + Terraform for Azure Databricks environments, with a network
boundary that keeps data exfiltration paths closed off by default.

## Layout

### [`01bootstrap`](01bootstrap/README.md)

One-time bootstrap of the Terraform state backend for **this repo only**.

Applied once with a local state file, which is then migrated into the
storage account it creates. After migration the local `terraform.tfstate`
is deleted and `01bootstrap` runs against the remote backend like
everything else.

Nothing else in the organisation uses this storage account.

See its [Day 1 and Day 2 walkthrough](01bootstrap/README.md#bootstrap-day-1-and-day-2)
for how the bootstrap process works, step by step.

## Naming convention

Names in this repo (`01bootstrap/prd/env.hcl`) follow a short, fixed
pattern so resource names stay predictable and fit Azure's length limits.
`alpha-ai` is just the example project used in this repo - swap it, the
region, and the environment for your own when you reuse this module.

| Token | Meaning |
|---|---|
| `alpha-ai` | Project name - example project used in this repo, rename to yours |
| `alai` | Project name, shortened - storage account names can't have hyphens and are capped at 24 characters, so `alpha-ai` becomes `alai` there |
| `eus` | Region, shortened - East US (`location = "eastus"`) |
| `prd` | Environment - production |
| `01` | Sequence number - first instance of this resource |

Put together: `01saeusprdalaitfstate` reads as *storage account #1, East US,
production, alpha-ai, terraform state*.
