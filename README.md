# azure-databricks-infrastructure

Terragrunt + Terraform for Azure Databricks environments, with a network
boundary that keeps data exfiltration paths closed off by default.

## Bootstrap

One-time bootstrap of the Terraform state backend for **this repo only**,
in [`01bootstrap`](01bootstrap/README.md).

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
`alpha-ai` is just the example project used here - swap the project,
region, and environment for your own when you reuse this module. Storage
account names can't contain hyphens and are capped at 24 characters, so
`alpha-ai` shortens to `alai` there.

| Token      | Meaning                 |
|------------|-------------------------|
| `alpha-ai` | Example project name    |
| `alai`     | Project name, shortened |
| `eus`      | East US region          |
| `prd`      | Production environment  |
| `01`       | Sequence number         |

Put together: `01saeusprdalaitfstate` reads as *storage account #1, East US,
production, alpha-ai, terraform state*.
