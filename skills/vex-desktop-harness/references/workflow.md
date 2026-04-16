# Vex desktop harness workflow

Use `scripts/vex_desktop_harness.sh` as the single entrypoint for desktop launch, readiness checks, and log discovery.

## Surface selection

- `start storybook`:
  Use for isolated component work and visual regression review. The main stories worth checking are `ThreadView`, `ShellWorkspace`, `WorkspacePages`, and `VcsInspectorRail`.
- `start vite`:
  Use for the real React app shell without the native wrapper. This is useful when debugging layout, routing, or client state but not Tauri-specific APIs.
- `start tauri-dev`:
  Use for native-shell behavior, Rust command wiring, terminal/native surfaces, and anything that depends on the actual desktop app window.
- `build desktop`:
  Use for a quick TypeScript and Vite compilation check.
- `build tauri`:
  Use when you need the Rust/Tauri build path, not just the front-end bundle.

## Standard loop

1. Run `status` to see whether ports or managed processes already exist.
2. Run `doctor` when this is the first boot in a session or the environment looks broken.
3. Run `start <surface>`.
4. Run `wait <surface>` before assuming the surface is usable.
5. Run `smoke <surface>` when you need a stable artifact directory and a probe result.
6. Run `logs <surface> 120` if readiness fails or the surface behaves unexpectedly.
7. Run `artifacts` to inspect the latest artifact bundle.
8. Run `stop <surface>` or `stop all` when you are done.

## Important implementation details

- Storybook listens on `http://localhost:6006`.
- Standalone Vite listens on `http://127.0.0.1:1420`.
- `tauri-dev` also depends on port `1420`, because [desktop/src-tauri/tauri.conf.json](/Users/pz/w/vex/desktop/src-tauri/tauri.conf.json) points Tauri at `http://localhost:1420`.
- `pnpm tauri dev` is routed through [desktop/scripts/run-tauri.mjs](/Users/pz/w/vex/desktop/scripts/run-tauri.mjs), which automatically selects [desktop/src-tauri/tauri.dev.conf.json](/Users/pz/w/vex/desktop/src-tauri/tauri.dev.conf.json) for dev runs.
- Do not run standalone `vite` and `tauri-dev` together; both want port `1420`.

## Command summary

- `status`: show paths, managed process state, per-service log locations, and whether ports are listening
- `paths`: print the temp state directory plus pid/log file paths for every managed service
- `doctor`: verify the desktop workspace, CLI prerequisites, pnpm-provided Vite/Tauri binaries, Rust metadata, and macOS command line tools
- `smoke storybook --story <story-id-or-title>`: start Storybook if needed, wait, resolve the requested story, verify the iframe shell, and create an artifact bundle
- `smoke vite`: start the standalone Vite surface if needed, wait, verify the root HTML shell, and create an artifact bundle
- `smoke tauri-dev`: start Tauri if needed, wait, record the configured app/window target, and create an artifact bundle
- `artifacts`: print the artifact root, latest artifact directory, manifest path, and all files captured in the latest run
- `logs <service> [lines]`: tail a specific log file with a configurable line count
- `wait <service> [timeout]`: block until the service is ready or fail with recent logs

## State and logs

State, pid files, and logs live under a temp directory derived from the desktop workspace path:

- `${TMPDIR:-/tmp}/vex-desktop-harness-<hash>`

Smoke artifacts live under `${TMPDIR:-/tmp}/vex-desktop-harness-<hash>/artifacts`, with the most recent run exposed through `artifacts` and the `latest` pointer inside that directory.

Use `paths` whenever you need the exact log file to inspect, attach to a bug report, or compare across runs.
