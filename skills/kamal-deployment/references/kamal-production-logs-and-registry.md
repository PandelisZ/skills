# Kamal production logs and registry guide

## Log triage sequence

1. Check host/container states.

```bash
kamal details
kamal app containers
kamal app version
```

2. Capture app logs while issue reproduces.

```bash
kamal app logs
```

3. Read command timeline (including registry and deploy transitions).

```bash
kamal audit
```

4. If multiple hosts differ, filter by role/host and compare timestamps.

5. If config mismatch is suspected, inspect `.kamal`-level files and run `kamal config` for merged settings.

## Registry validation steps

1. Validate config quickly:

```bash
kamal config
```

2. Validate authentication + remote access:

```bash
kamal registry login
```

3. If needed, remove stale sessions:

```bash
kamal registry logout
```

4. Force local image pipeline test:

```bash
kamal deploy --skip-push
```

Use this after you've confirmed the image is already present on hosts and only need runtime/container reroute/restart diagnostics.

## Local registry across network

- `registry.server` values that start with `localhost` indicate a host-local registry.
- for cross-host network distribution, set `registry.server` to a resolvable host/IP (for example `registry.internal.example:5000`).
- ensure all deployment hosts can connect to that registry endpoint.
- keep authentication secrets out of YAML as plain values; reference them as secret names.

## Deployment-safe rollback pattern

1. Set maintenance mode if traffic impact is high.
2. Identify previous stable version via logs or `kamal app containers -q`.
3. Run `kamal rollback <prev_version>`.
4. Monitor `kamal app logs` and `kamal audit` until recovery is stable.
5. Return to live mode.
