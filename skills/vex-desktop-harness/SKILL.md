---
name: vex-desktop-harness
description: Launch, build, diagnose, and stop the Vex desktop surfaces from `/Users/pz/w/vex/desktop`. Use when Codex needs to run Storybook, the standalone Vite shell, or the real Tauri desktop app; inspect ports, readiness, and logs; troubleshoot desktop boot failures; or prepare the app for screenshot-based visual verification.
---

# Vex Desktop Harness

Use the bundled harness script as the primary interface for running Vex desktop surfaces. Prefer it over ad hoc shell commands so process lifecycle, ports, readiness checks, smoke probes, and artifacts stay predictable between turns.

Pair this skill with `tauri-ui-verify` when you need screenshots or a visual desktop proof after the app boots.

## Primary Entry Point

Run:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh <command>
```

Read [references/workflow.md](references/workflow.md) for the surface-selection matrix and [references/debugging.md](references/debugging.md) for desktop-specific debugging guidance.

## Default Loop

1. Run `status` to see whether another process already owns the relevant port.
2. Run `doctor` when the first boot fails, dependencies look stale, or the environment is unclear.
3. Run `start <surface>`.
4. Run `wait <surface>` before assuming the surface is usable.
5. Run `logs <surface> 120` if boot fails or the UI behaves unexpectedly.
6. Run `smoke <surface>` when you need a repeatable probe plus an artifact bundle.
7. Run `artifacts` to inspect the latest probe output.
8. Run `stop <surface>` or `stop all` when you are done.

## Choose the Surface

- Use `storybook` for isolated visual work and story-driven debugging. The key stories live under `ThreadView`, `ShellWorkspace`, `WorkspacePages`, and `VcsInspectorRail`.
- Use `vite` for the real React shell when you do not need native Tauri APIs or the desktop window.
- Use `tauri-dev` for native-shell behavior, Rust/Tauri command wiring, terminal/native surfaces, and any issue that only exists in the actual desktop app.
- Use `build desktop` for a fast frontend compile check.
- Use `build tauri` for the Rust/Tauri build path.

## Common Commands

- Check status:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh status
```

- Print the exact pid/log file locations:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh paths
```

- Verify the local desktop toolchain and workspace wiring:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh doctor
```

- Start Storybook for isolated UI review:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh start storybook
```

- Start the real desktop shell:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh start tauri-dev
```

- Wait until a managed service is ready:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh wait tauri-dev 90
```

- Run a Storybook smoke probe and resolve a real story selector:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh smoke storybook --story desktop-threadview--thread-with-tool-calls
```

- Run a Vite smoke probe:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh smoke vite
```

- Run a Tauri smoke probe:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh smoke tauri-dev
```

- Build the desktop frontend:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh build desktop
```

- Build Storybook:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh build storybook
```

- Stop managed services:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh stop all
```

- Inspect the last log lines for a managed service:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh logs storybook 120
```

- Inspect the latest artifact bundle:

```bash
/Users/pz/.codex/skills/vex-desktop-harness/scripts/vex_desktop_harness.sh artifacts
```

## Rules

- Use `start storybook` for component and interaction review.
- Use `start tauri-dev` only when the task genuinely needs the Tauri shell or desktop-specific behavior.
- Use `smoke storybook` or `smoke vite` when you need a reproducible URL, log path, and artifact directory for browser automation.
- Use `smoke tauri-dev` when you need a reproducible artifact directory before a native-window screenshot pass.
- Do not run standalone `vite` and `tauri-dev` together. `tauri-dev` starts its own Vite server through Tauri’s `beforeDevCommand`, and both want port `1420`.
- Use `status` before starting services if there is any chance another process is already active.
- Use `wait` before screenshots, visual review, or claiming that a surface is up.
- If `status` says a port is listening but unmanaged, do not assume this skill started it; either reuse it deliberately or stop it outside the harness first.
- Use `logs <service>`, `paths`, and `artifacts` when a managed service fails to boot so the next debugging step has exact evidence.
- Use [references/debugging.md](references/debugging.md) when the issue could be native-only, permission-related, or tied to Rust/Tauri services.
- Keep the skill focused on the `desktop/` workspace unless the user explicitly asks for a different target.
