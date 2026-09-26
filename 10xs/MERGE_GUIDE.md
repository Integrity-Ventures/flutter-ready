# 10xs Governance OS — Merge Guide

## Incremental Update Instructions

When re-exporting your Project OS, follow these rules:

### Safe to Overwrite (Machine-Managed)

These paths are regenerated on every export:

- `10xs/architecture/generated/` — Blueprint, Decomposition, Export Status
- `10xs/governance/` — Governance profile, kernel version, schemas
- `10xs/CLAUDE.md` — AI governance adapter
- `10xs/PRD.md` — Project requirements snapshot
- `10xs/README.md` — Onboarding guide
- `10xs/.mcp.json` — MCP server configuration

### Never Overwrite (User-Managed)

These paths contain your local work and are enforced as never-overwritten by the 10xs-sync client (a re-fetch skips them and reports them; there is no server copy to restore from):

- `10xs/workflow/` — Your execution artifacts, session notes, reports
- `10xs/architecture/local/` — Your local architecture decisions

### Doctrine Updates

`10xs/doctrine/` is version-pinned to the kernel.

Check `10xs/governance/KERNEL_VERSION.json` — if the version matches your
current one, doctrine is unchanged and does not need updating. If the kernel
version has changed, replace your doctrine files with the new export.
