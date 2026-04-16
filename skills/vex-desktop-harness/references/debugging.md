# Vex desktop debugging guide

## Triage the surface first

- Reproduce in Storybook when the issue is purely visual or isolated to a component state. Start with stories such as `ThreadView`, `ShellWorkspace`, `WorkspacePages`, and `VcsInspectorRail`.
- Reproduce in `vite` when the bug needs the real React app shell but not the native Tauri wrapper.
- Reproduce in `tauri-dev` when the bug depends on the native shell, Rust commands, terminal surfaces, desktop permissions, or window behavior.

## Read the right evidence

- Use `scripts/vex_desktop_harness.sh logs tauri-dev 120` for launch failures, Rust panics, and Tauri command errors.
- Use `scripts/vex_desktop_harness.sh logs vite 120` for browser-side startup failures and HMR issues.
- Use `scripts/vex_desktop_harness.sh logs storybook 120` when stories fail to compile or the Storybook router breaks.
- Use `scripts/vex_desktop_harness.sh paths` to find the temp state directory and the exact log file paths.
- Use `scripts/vex_desktop_harness.sh artifacts` to inspect the latest smoke bundle before rerunning anything.

## Know where the app emits useful state

- Front-end top-level runtime errors surface in [desktop/src/main.tsx](/Users/pz/w/vex/desktop/src/main.tsx).
- Session-orchestration breadcrumbs accumulate in [desktop/src/lib/session-debug.ts](/Users/pz/w/vex/desktop/src/lib/session-debug.ts).
- Enable verbose session logging in the app with `localStorage.setItem('vex:debug:session', '1')`, then reproduce the issue and inspect `window.__VEX_SESSION_DEBUG__` or console output.
- Tauri command registration and major service wiring live in [desktop/src-tauri/src/lib.rs](/Users/pz/w/vex/desktop/src-tauri/src/lib.rs).
- Native terminal and shell integration live under [desktop/src-tauri/src/native_terminal/mod.rs](/Users/pz/w/vex/desktop/src-tauri/src/native_terminal/mod.rs) and [desktop/src-tauri/src/terminal/mod.rs](/Users/pz/w/vex/desktop/src-tauri/src/terminal/mod.rs).
- Codex and scheduler runtime behavior live under [desktop/src-tauri/src/codex/service.rs](/Users/pz/w/vex/desktop/src-tauri/src/codex/service.rs) and [desktop/src-tauri/src/codex/scheduler.rs](/Users/pz/w/vex/desktop/src-tauri/src/codex/scheduler.rs).
- Workspace/VCS integration lives in [desktop/src-tauri/src/vcs/service.rs](/Users/pz/w/vex/desktop/src-tauri/src/vcs/service.rs).

## Common failure modes

- Port `1420` already busy:
  `tauri-dev` launches its own Vite server via `beforeDevCommand`, so stop any standalone `vite` process before starting Tauri.
- Port `6006` already busy:
  Storybook is probably already running elsewhere; decide whether to reuse it or stop it before starting a harness-managed process.
- White or blank desktop window:
  Confirm `tauri-dev` is still running, confirm port `1420` is listening, read the last `120` tauri log lines, then compare the same screen in Storybook or `vite` to decide whether the breakage is native-only. Use `smoke tauri-dev` first so you have a stable artifact directory before capturing screenshots.
- Tauri app never appears:
  Run `doctor`, then inspect the tauri log for Rust compile errors, missing tooling, or macOS build failures.
- Screenshot capture fails:
  That is usually a Screen Recording permission issue, not an app failure. Re-run the screenshot permission preflight before capturing evidence.

## Evidence to collect before patching

- The surface used: `storybook`, `vite`, or `tauri-dev`
- The exact command and whether `wait` succeeded
- Screenshot path(s) for the broken state
- The relevant log file path and a short excerpt
- Whether the bug reproduces outside Tauri
