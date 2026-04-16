---
name: kamal-deployment
description: Help with Kamal deployment workflows for setup, deploy, rollback, production log diagnostics, and Docker registry configuration for local or cross-host image publishing.
---

# Kamal Deployment

## What this skill covers

Use this skill when a user needs Kamal deployment help, including:

- setting up `config/deploy.yml` and `.kamal/secrets`
- executing `setup`, `deploy`, and `redeploy`
- troubleshooting production runtime and rollout failures
- configuring Docker registry publishing for local and networked environments

## Quick playbooks

1. Follow the command and incident workflows in [Kamal deployment commands](references/kamal-deploy-commands.md).
2. Follow the log review and registry setup playbook in [Logs and registry troubleshooting](references/kamal-production-logs-and-registry.md).

## Core command flow

1. Ensure `config/deploy.yml` and `.kamal/secrets` are valid.
2. Run `kamal setup` on first install.
3. Use `kamal deploy` for normal releases.
4. Use `kamal redeploy` only after a successful first deploy.
5. Use `kamal rollback` for release rollback.
6. Use log and audit commands to validate or triage failures.

## Production incident checklist

- Put the app in maintenance mode: `kamal app maintenance`.
- Capture deployment state: `kamal details`, `kamal app version`, `kamal audit`.
- Capture runtime output: `kamal app logs`.
- Inspect container health and stale containers: `kamal app containers`, `kamal app stale_containers`.
- Roll back quickly if health is broken: `kamal rollback <VERSION>`.
- Return to service once fixed: `kamal app live`.

## Deployment command map

- `kamal setup`: bootstrap first-time hosts, deploy, and install Docker if needed.
- `kamal deploy`: build image, push/pull registry image, healthcheck, cutover, prune.
- `kamal redeploy`: same as deploy without setup/proxy bootstrap/prune/registry login.
- `kamal rollback [VERSION]`: revert to previous deployed version.
- `kamal registry login | logout | setup`: test or change registry authentication and sessions.
- `kamal app details | containers | images | logs | version | stale_containers` for app operations.
- `kamal audit`: review recent command execution history from `.kamal/app-audit.log`.
- `kamal prune`: remove unused containers and images.

## Local Docker registry playbook

1. Local single host:

```yaml
registry:
  server: localhost:5555
```

Kamal starts a local Docker registry on that endpoint and pushes images there.

2. Cross-host/networked registry:

```yaml
registry:
  server: registry.internal.example:5555
  username:
    - KAMAL_REGISTRY_USER
  password:
    - KAMAL_REGISTRY_PASSWORD
```

Requirements:

- `registry.server` must resolve from all servers.
- all hosts must reach the registry port.
- credentials must exist in local environment and `.kamal/secrets`.
- validate with `kamal registry login` before first deploy.
- if registry uses plain HTTP, configure Docker daemon trust/insecure settings on host and any deployment hosts accordingly.

For rollback and diagnosis, use `kamal registry login` after any credential/port/path change.
