# Kamal command references

## Canonical docs used by this skill

- Kamal install/setup flow: https://kamal-deploy.org/docs/installation/
- Kamal setup: https://kamal-deploy.org/docs/commands/setup/
- Kamal deploy: https://kamal-deploy.org/docs/commands/deploy/
- Kamal redeploy: https://kamal-deploy.org/docs/commands/redeploy/
- Kamal registry command: https://kamal-deploy.org/docs/commands/registry/
- Kamal app command: https://kamal-deploy.org/docs/commands/app/
- Kamal audit command: https://kamal-deploy.org/docs/commands/audit/
- Kamal details command: https://kamal-deploy.org/docs/commands/details/

## Commands by objective

- Initial bootstrap
  - `kamal setup`
  - `kamal registry setup`
  - `kamal app exec --help` (host-level app-shell style checks)

- Normal release
  - `kamal deploy`
  - `kamal redeploy`
  - `kamal prune`

- Release control and rollback
  - `kamal rollback [VERSION]`
  - `kamal lock` (if deployment lock behavior is needed)

- Production debugging
  - `kamal details -q`
  - `kamal app version`
  - `kamal app containers`
  - `kamal app images`
  - `kamal app logs`
  - `kamal audit`

- Maintenance mode
  - `kamal app maintenance`
  - `kamal app live`

## High-signal troubleshooting order

1. `kamal app version` to see deployed SHA by host.
2. `kamal details` for failed/exited container state.
3. `kamal app logs` for error tracebacks.
4. `kamal audit` for deployment command history and timing.
5. `kamal rollback` if the current version is unrecoverable.

