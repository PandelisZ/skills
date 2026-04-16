#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class HarnessError(RuntimeError):
    pass


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def artifact_root(state_dir: Path) -> Path:
    return state_dir / "artifacts"


def latest_artifact_dir(root: Path) -> Path | None:
    latest_link = root / "latest"
    if latest_link.is_symlink():
      return latest_link.resolve()
    latest_text = root / "latest.txt"
    if latest_text.exists():
        candidate = Path(latest_text.read_text().strip())
        if candidate.exists():
            return candidate
    candidates = [path for path in root.iterdir() if path.is_dir() and path.name != "latest"]
    if not candidates:
        return None
    return max(candidates, key=lambda path: path.stat().st_mtime)


def create_artifact_dir(root: Path, service: str) -> Path:
    root.mkdir(parents=True, exist_ok=True)
    stem = f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-{service}"
    artifact_dir = root / stem
    suffix = 1
    while artifact_dir.exists():
        artifact_dir = root / f"{stem}-{suffix}"
        suffix += 1
    artifact_dir.mkdir(parents=True, exist_ok=False)

    latest_link = root / "latest"
    latest_text = root / "latest.txt"
    if latest_link.is_symlink() or latest_link.exists():
        if latest_link.is_dir() and not latest_link.is_symlink():
            shutil.rmtree(latest_link)
        else:
            latest_link.unlink()
    try:
        latest_link.symlink_to(artifact_dir.name)
        if latest_text.exists():
            latest_text.unlink()
    except OSError:
        latest_text.write_text(f"{artifact_dir}\n")
    return artifact_dir


def read_manifest(artifact_dir: Path) -> dict:
    manifest_path = artifact_dir / "manifest.json"
    if not manifest_path.exists():
        return {}
    return json.loads(manifest_path.read_text())


def write_manifest(artifact_dir: Path, **updates: object) -> tuple[Path, dict]:
    manifest = read_manifest(artifact_dir)
    if "created_at" not in manifest:
        manifest["created_at"] = now_iso()
    for key, value in updates.items():
        if value is not None:
            manifest[key] = value
    manifest["artifact_dir"] = str(artifact_dir)
    manifest["updated_at"] = now_iso()
    manifest_path = artifact_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return manifest_path, manifest


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def write_json(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def request_text(url: str) -> tuple[int, dict[str, str], str]:
    request = Request(url, headers={"User-Agent": "vex-desktop-harness"})
    with urlopen(request, timeout=20) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        body = response.read().decode(charset, errors="replace")
        return response.status, dict(response.headers), body


def request_json(url: str) -> tuple[int, dict[str, str], object, str]:
    status, headers, body = request_text(url)
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as exc:
        raise HarnessError(f"invalid JSON from {url}: {exc}") from exc
    return status, headers, payload, body


def command_output(output: subprocess.CompletedProcess[str]) -> str:
    parts = []
    if output.stdout.strip():
        parts.append(output.stdout.strip())
    if output.stderr.strip():
        parts.append(output.stderr.strip())
    return "\n".join(parts).strip()


def run_harness(script_path: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(script_path), *args],
        capture_output=True,
        text=True,
    )


def log_path(state_dir: Path, service: str) -> Path:
    return state_dir / f"{service}.log"


def pid_path(state_dir: Path, service: str) -> Path:
    return state_dir / f"{service}.pid"


def tail_file(path: Path, lines: int = 120) -> str:
    if not path.exists():
        return ""
    content = path.read_text(errors="replace").splitlines()
    return "\n".join(content[-lines:]) + ("\n" if content else "")


def resolve_story_selector(base_url: str, selector: str, artifact_dir: Path) -> dict[str, str]:
    index_url = f"{base_url}/index.json"
    status, headers, payload, raw_body = request_json(index_url)
    if status >= 400:
        raise HarnessError(f"Storybook index request failed with status {status}")
    write_json(artifact_dir / "index-headers.json", headers)
    write_text(artifact_dir / "index.json", raw_body)

    entries = payload.get("entries") if isinstance(payload, dict) else None
    if not isinstance(entries, dict):
        stories = payload.get("stories") if isinstance(payload, dict) else None
        if isinstance(stories, dict):
            entries = stories
    if not isinstance(entries, dict):
        raise HarnessError("Storybook index.json did not contain an entries map")

    candidates = []
    for entry_id, entry in entries.items():
        if not isinstance(entry, dict):
            continue
        if entry.get("type") not in (None, "story"):
            continue
        title = str(entry.get("title") or "").strip()
        name = str(entry.get("name") or "").strip()
        full_title = "/".join(part for part in [title, name] if part)
        candidates.append(
            {
                "id": str(entry.get("id") or entry_id),
                "title": title,
                "name": name,
                "full_title": full_title,
            }
        )

    if not candidates:
        raise HarnessError("Storybook index did not expose any stories")

    selector_lower = selector.lower()

    def pick(matches: list[dict[str, str]], label: str) -> dict[str, str]:
        if len(matches) == 1:
            return matches[0]
        if len(matches) > 1:
            options = ", ".join(match["full_title"] or match["id"] for match in matches[:8])
            raise HarnessError(f"story selector '{selector}' matched multiple {label}: {options}")
        return {}

    match_groups = [
        ("story ids", [candidate for candidate in candidates if candidate["id"] == selector]),
        ("story titles", [candidate for candidate in candidates if candidate["full_title"] == selector]),
        ("story titles", [candidate for candidate in candidates if candidate["title"] == selector]),
        ("story names", [candidate for candidate in candidates if candidate["name"] == selector]),
        (
            "story ids",
            [candidate for candidate in candidates if candidate["id"].lower() == selector_lower],
        ),
        (
            "story titles",
            [candidate for candidate in candidates if candidate["full_title"].lower() == selector_lower],
        ),
        (
            "story titles",
            [candidate for candidate in candidates if candidate["title"].lower() == selector_lower],
        ),
        (
            "story names",
            [candidate for candidate in candidates if candidate["name"].lower() == selector_lower],
        ),
        (
            "story titles",
            [candidate for candidate in candidates if selector_lower in candidate["full_title"].lower()],
        ),
    ]

    for label, matches in match_groups:
        selected = pick(matches, label)
        if selected:
            return selected

    sample = ", ".join(candidate["full_title"] or candidate["id"] for candidate in candidates[:10])
    raise HarnessError(f"story selector '{selector}' did not match any story; available examples: {sample}")


def tauri_target(desktop_dir: Path) -> dict[str, str]:
    config_path = desktop_dir / "src-tauri" / "tauri.dev.conf.json"
    payload = json.loads(config_path.read_text())
    windows = payload.get("app", {}).get("windows", [])
    first_window = windows[0] if windows else {}
    app_target = str(payload.get("productName") or "Vex Dev")
    window_target = str(first_window.get("title") or app_target)
    return {
        "app_target": app_target,
        "window_target": window_target,
    }


def print_paths(args: argparse.Namespace) -> int:
    root = artifact_root(args.state_dir)
    latest = latest_artifact_dir(root) if root.exists() else None
    print(f"repo: {args.repo_root}")
    print(f"desktop: {args.desktop_dir}")
    print(f"state: {args.state_dir}")
    print(f"artifacts_root: {root}")
    if latest:
        print(f"latest_artifact_dir: {latest}")
    for service in ("storybook", "vite", "tauri-dev"):
        print(f"{service} pid file: {pid_path(args.state_dir, service)}")
        print(f"{service} log: {log_path(args.state_dir, service)}")
    return 0


def print_artifacts(args: argparse.Namespace) -> int:
    root = artifact_root(args.state_dir)
    print(f"artifacts_root: {root}")
    if not root.exists():
        print("latest_artifact_dir: ")
        return 1
    latest = latest_artifact_dir(root)
    if latest is None:
        print("latest_artifact_dir: ")
        return 1
    manifest_path = latest / "manifest.json"
    print(f"latest_artifact_dir: {latest}")
    print(f"manifest: {manifest_path}")
    for path in sorted(file for file in latest.rglob("*") if file.is_file()):
        print(f"file: {path}")
    return 0


def doctor_exec(label: str, command: list[str]) -> bool:
    if subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        print(f"[ok] {label}")
        return True
    print(f"[fail] {label}", file=sys.stderr)
    return False


def run_doctor(args: argparse.Namespace) -> int:
    failures = 0
    commands = [
        ("pnpm", "pnpm"),
        ("cargo", "cargo"),
        ("rustc", "rustc"),
        ("lsof", "lsof"),
        ("python3", "python3"),
    ]
    for label, command_name in commands:
        resolved = shutil.which(command_name)
        if resolved:
            print(f"[ok] {label}: {resolved}")
        else:
            print(f"[fail] {label}: missing command {command_name}", file=sys.stderr)
            failures += 1

    files = [
        ("desktop package", args.desktop_dir / "package.json"),
        ("tauri manifest", args.desktop_dir / "src-tauri" / "Cargo.toml"),
        ("tauri config", args.desktop_dir / "src-tauri" / "tauri.conf.json"),
        ("tauri dev config", args.desktop_dir / "src-tauri" / "tauri.dev.conf.json"),
        ("tauri launcher", args.desktop_dir / "scripts" / "run-tauri.mjs"),
        ("harness helper", args.helper_script),
    ]
    for label, path in files:
        if path.exists():
            print(f"[ok] {label}: {path}")
        else:
            print(f"[fail] {label}: missing {path}", file=sys.stderr)
            failures += 1

    checks = [
        ("desktop Vite CLI resolves through pnpm", ["pnpm", "--dir", str(args.desktop_dir), "exec", "vite", "--version"]),
        ("desktop Tauri CLI resolves through pnpm", ["pnpm", "--dir", str(args.desktop_dir), "exec", "tauri", "--version"]),
        ("desktop Rust metadata loads", ["cargo", "metadata", "--manifest-path", str(args.desktop_dir / "src-tauri" / "Cargo.toml"), "--no-deps"]),
    ]
    for label, command in checks:
        if not doctor_exec(label, command):
            failures += 1

    if sys.platform == "darwin" and not doctor_exec("xcode command line tools are installed", ["xcode-select", "-p"]):
        failures += 1

    if failures:
        print(f"doctor: {failures} check(s) failed", file=sys.stderr)
        return 1
    print("doctor: all checks passed")
    return 0


def smoke_storybook(args: argparse.Namespace, artifact_dir: Path) -> dict[str, object]:
    if not args.story:
        raise HarnessError("storybook smoke requires --story <story-id-or-title>")

    start_result = run_harness(args.harness_script, "start", "storybook")
    start_output = command_output(start_result)
    write_text(artifact_dir / "start-output.txt", start_output + ("\n" if start_output else ""))
    if start_result.returncode != 0:
        raise HarnessError(start_output or "storybook start failed")

    wait_result = run_harness(args.harness_script, "wait", "storybook", str(args.timeout))
    wait_output = command_output(wait_result)
    write_text(artifact_dir / "wait-output.txt", wait_output + ("\n" if wait_output else ""))
    if wait_result.returncode != 0:
        raise HarnessError(wait_output or "storybook did not become ready")

    base_url = f"http://localhost:{args.storybook_port}"
    selected = resolve_story_selector(base_url, args.story, artifact_dir)
    story_url = f"{base_url}/?path=/story/{selected['id']}"
    iframe_url = f"{base_url}/iframe.html?id={selected['id']}&viewMode=story"
    status, headers, body = request_text(iframe_url)
    if status >= 400:
        raise HarnessError(f"storybook iframe returned HTTP {status}")
    write_json(artifact_dir / "iframe-headers.json", headers)
    write_text(artifact_dir / "iframe.html", body)
    if "storybook-root" not in body and "<!doctype html" not in body.lower():
        raise HarnessError("storybook iframe responded without the expected HTML shell")

    return {
        "service": "storybook",
        "status": "ok",
        "story_selector": args.story,
        "story_id": selected["id"],
        "story_title": selected["title"],
        "story_name": selected["name"],
        "story_url": story_url,
        "url": story_url,
        "iframe_url": iframe_url,
        "log_path": str(log_path(args.state_dir, "storybook")),
        "notes": start_output,
    }


def smoke_vite(args: argparse.Namespace, artifact_dir: Path) -> dict[str, object]:
    start_result = run_harness(args.harness_script, "start", "vite")
    start_output = command_output(start_result)
    write_text(artifact_dir / "start-output.txt", start_output + ("\n" if start_output else ""))
    if start_result.returncode != 0:
        raise HarnessError(start_output or "vite start failed")

    wait_result = run_harness(args.harness_script, "wait", "vite", str(args.timeout))
    wait_output = command_output(wait_result)
    write_text(artifact_dir / "wait-output.txt", wait_output + ("\n" if wait_output else ""))
    if wait_result.returncode != 0:
        raise HarnessError(wait_output or "vite did not become ready")

    url = f"http://127.0.0.1:{args.vite_port}"
    status, headers, body = request_text(url)
    if status >= 400:
        raise HarnessError(f"vite root returned HTTP {status}")
    write_json(artifact_dir / "index-headers.json", headers)
    write_text(artifact_dir / "index.html", body)
    lowered = body.lower()
    if "<!doctype html" not in lowered and 'id="root"' not in lowered and "id='root'" not in lowered:
        raise HarnessError("vite root responded without the expected app shell HTML")

    return {
        "service": "vite",
        "status": "ok",
        "url": url,
        "log_path": str(log_path(args.state_dir, "vite")),
        "notes": start_output,
    }


def smoke_tauri(args: argparse.Namespace, artifact_dir: Path) -> dict[str, object]:
    start_result = run_harness(args.harness_script, "start", "tauri-dev")
    start_output = command_output(start_result)
    write_text(artifact_dir / "start-output.txt", start_output + ("\n" if start_output else ""))
    if start_result.returncode != 0:
        raise HarnessError(start_output or "tauri-dev start failed")

    wait_result = run_harness(args.harness_script, "wait", "tauri-dev", str(args.timeout))
    wait_output = command_output(wait_result)
    write_text(artifact_dir / "wait-output.txt", wait_output + ("\n" if wait_output else ""))
    if wait_result.returncode != 0:
        raise HarnessError(wait_output or "tauri-dev did not become ready")

    target = tauri_target(args.desktop_dir)
    write_json(artifact_dir / "tauri-target.json", target)
    log_tail = tail_file(log_path(args.state_dir, "tauri-dev"))
    if log_tail:
        write_text(artifact_dir / "log-tail.txt", log_tail)

    return {
        "service": "tauri-dev",
        "status": "ok",
        "url": f"http://localhost:{args.vite_port}",
        "log_path": str(log_path(args.state_dir, "tauri-dev")),
        "app_target": target["app_target"],
        "window_target": target["window_target"],
        "notes": start_output,
    }


def print_smoke_result(result: dict[str, object], manifest_path: Path, artifact_dir: Path) -> None:
    ordered_keys = [
        "service",
        "status",
        "story_selector",
        "story_id",
        "story_title",
        "story_name",
        "url",
        "story_url",
        "iframe_url",
        "app_target",
        "window_target",
        "log_path",
        "error",
        "notes",
    ]
    for key in ordered_keys:
        value = result.get(key)
        if value is None or value == "":
            continue
        print(f"{key}: {value}")
    print(f"artifact_dir: {artifact_dir}")
    print(f"manifest: {manifest_path}")


def run_smoke(args: argparse.Namespace) -> int:
    service = args.surface
    artifact_dir = create_artifact_dir(artifact_root(args.state_dir), service)
    manifest_path, result = write_manifest(
        artifact_dir,
        service=service,
        status="running",
        log_path=str(log_path(args.state_dir, service)),
        story_selector=getattr(args, "story", None),
    )

    try:
        if service == "storybook":
            result = smoke_storybook(args, artifact_dir)
        elif service == "vite":
            result = smoke_vite(args, artifact_dir)
        elif service == "tauri-dev":
            result = smoke_tauri(args, artifact_dir)
        else:
            raise HarnessError(f"unsupported smoke surface: {service}")
        manifest_path, result = write_manifest(artifact_dir, **result)
        print_smoke_result(result, manifest_path, artifact_dir)
        return 0
    except (HarnessError, HTTPError, URLError, OSError, json.JSONDecodeError) as exc:
        error_message = str(exc)
        write_text(artifact_dir / "error.txt", error_message + "\n")
        current_log_path = log_path(args.state_dir, service)
        current_log_tail = tail_file(current_log_path)
        if current_log_tail:
            write_text(artifact_dir / "log-tail.txt", current_log_tail)
        manifest_path, result = write_manifest(
            artifact_dir,
            service=service,
            status="error",
            log_path=str(current_log_path),
            error=error_message,
            story_selector=getattr(args, "story", None),
        )
        print_smoke_result(result, manifest_path, artifact_dir)
        return 1


def parse_args() -> argparse.Namespace:
    helper_script = Path(__file__).resolve()
    harness_script = helper_script.with_name("vex_desktop_harness.sh")
    parser = argparse.ArgumentParser(description="Helper commands for the Vex desktop harness.")
    parser.add_argument("--repo-root", required=True, type=Path)
    parser.add_argument("--desktop-dir", required=True, type=Path)
    parser.add_argument("--state-dir", required=True, type=Path)
    parser.add_argument("--storybook-port", required=True, type=int)
    parser.add_argument("--vite-port", required=True, type=int)
    parser.add_argument("--harness-script", default=harness_script, type=Path)
    parser.add_argument("--helper-script", default=helper_script, type=Path)

    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("doctor")
    subparsers.add_parser("paths")
    subparsers.add_parser("artifacts")

    smoke_parser = subparsers.add_parser("smoke")
    smoke_subparsers = smoke_parser.add_subparsers(dest="surface", required=True)

    storybook_parser = smoke_subparsers.add_parser("storybook")
    storybook_parser.add_argument("--story", required=True)
    storybook_parser.add_argument("--timeout", type=int, default=60)

    vite_parser = smoke_subparsers.add_parser("vite")
    vite_parser.add_argument("--timeout", type=int, default=60)

    tauri_parser = smoke_subparsers.add_parser("tauri-dev")
    tauri_parser.add_argument("--timeout", type=int, default=90)

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.command == "doctor":
        return run_doctor(args)
    if args.command == "paths":
        return print_paths(args)
    if args.command == "artifacts":
        return print_artifacts(args)
    if args.command == "smoke":
        return run_smoke(args)
    raise HarnessError(f"unknown helper command: {args.command}")


if __name__ == "__main__":
    sys.exit(main())
