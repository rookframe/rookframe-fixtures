"""Install the committed UI runtime without rewriting resource paths or UIDs."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
import tempfile

SOURCE = "https://github.com/rookframe/rookframe-ui-kit.git"
PUBLIC_ROOT = "rookframe/ui/"
INVENTORY = ".plugged/rookframe-ui-kit-files.json"
PROVENANCE = "rookframe_ui_kit_provenance.json"


def git(checkout: Path, *args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(checkout), *args], stderr=subprocess.PIPE, timeout=120)


def committed_runtime(checkout: Path, revision: str) -> tuple[str, dict[str, bytes]]:
    """Resolve layout from the selected Git tree, never the working checkout."""
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("UI Kit requires a full commit SHA.")
    entries = [entry.split("\t", 1) for entry in git(checkout, "ls-tree", "-rz", revision).decode().split("\0") if entry]
    roots = [root for root in (PUBLIC_ROOT, "ui-kit/" + PUBLIC_ROOT)
             if any(name.startswith(root) for _, name in entries)]
    if len(roots) != 1:
        raise ValueError("UI Kit must contain exactly one supported core runtime layout.")
    root = roots[0]
    if any(metadata.startswith("160000 ") for metadata, name in entries if name.startswith(root)):
        raise ValueError("UI Kit core runtime must not contain Git submodules.")
    archive = git(checkout, "archive", revision, root)
    files = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
        for member in tree:
            if member.isdir():
                continue
            relative = member.name.removeprefix(root)
            if not member.name.startswith(root) or not member.isfile() or not relative or ".." in PurePosixPath(relative).parts:
                raise ValueError("UI Kit runtime must contain only regular files inside its public root.")
            files[relative] = tree.extractfile(member).read()
    if not files:
        raise ValueError("UI Kit runtime is empty.")
    return root.rstrip("/"), files


def safe_path(project: Path, relative: str) -> Path:
    parts = PurePosixPath(relative).parts
    if not parts or PurePosixPath(relative).is_absolute() or ".." in parts or "\\" in relative:
        raise ValueError("Invalid installer-owned path: " + relative)
    path = project
    for part in parts:
        path = path / part
        if path.is_symlink():
            raise ValueError("Dependency paths must not traverse symlinks: " + relative)
    if not path.resolve().is_relative_to(project.resolve()):
        raise ValueError("Dependency path leaves the project: " + relative)
    return path


def atomic_write(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
        temporary = Path(file.name)
        file.write(contents)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def encoded(value: object) -> bytes:
    return (json.dumps(value, indent=2) + "\n").encode()


def hashes(files: dict[str, bytes]) -> dict[str, str]:
    return {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}


def install_runtime(project: Path, selection: dict[str, str], *, previous_commit: str = "",
                    legacy_files: list[str] | None = None) -> dict:
    project = project.resolve()
    commit = selection["commit"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("UI Kit requires a full commit SHA.")
    cache = safe_path(project, ".plugged/rookframe-ui-kit")
    inventory_path = safe_path(project, INVENTORY)
    provenance_path = safe_path(project, PROVENANCE)
    old = json.loads(inventory_path.read_text()) if inventory_path.exists() else None
    # A legacy installation has no hash inventory. Its recorded revision supplies
    # the original bytes; gd-plug's destination list limits the adopted ownership.
    if old is None and cache.exists() and safe_path(project, PUBLIC_ROOT).exists():
        if not previous_commit and provenance_path.exists():
            previous_commit = json.loads(provenance_path.read_text())["commit"]
        if not previous_commit:
            previous_commit = git(cache, "rev-parse", "HEAD").decode().strip()
        _, previous = committed_runtime(cache, previous_commit)
        allowed = None if legacy_files is None else {name.removeprefix("res://").removeprefix(PUBLIC_ROOT) for name in legacy_files if name.startswith("res://" + PUBLIC_ROOT)}
        old = {"files": {name: digest for name, digest in hashes(previous).items()
                         if (allowed is None or name in allowed) and safe_path(project, PUBLIC_ROOT + name).exists()}}
    old_files = (old or {}).get("files", {})
    if not cache.exists():
        cache.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init", "--quiet", str(cache)], check=True, capture_output=True)
    available = subprocess.run(["git", "-C", str(cache), "cat-file", "-e", commit + "^{commit}"], capture_output=True)
    if available.returncode:
        git(cache, "fetch", "--quiet", "--depth=1", SOURCE, commit)
    source_root, files = committed_runtime(cache, commit)
    new_hashes = hashes(files)
    # Validate every destination and every stale owned file before any mutation.
    for name in old_files.keys() | files.keys():
        path = safe_path(project, PUBLIC_ROOT + name)
        if path.exists():
            if not path.is_file():
                raise ValueError("UI Kit destination is not a file: " + name)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if name in old_files:
                if digest != old_files[name]:
                    raise ValueError("Locally modified UI Kit resource: " + name)
            else:
                raise ValueError("UI Kit would overwrite an unrelated file: " + name)
    record = {"schemaVersion": 1, "commit": commit, "version": selection["tag"],
              "sourceRoot": source_root, "files": new_hashes}
    writes = {safe_path(project, PUBLIC_ROOT + name): data for name, data in files.items()}
    deletes = {safe_path(project, PUBLIC_ROOT + name) for name in old_files.keys() - files.keys()}
    writes[inventory_path] = encoded(record)
    # Do not leave successful provenance for the previous revision after switching.
    deletes.add(provenance_path)
    before = {path: path.read_bytes() if path.exists() else None for path in writes.keys() | deletes}
    try:
        for path, data in writes.items():
            if before[path] != data:
                atomic_write(path, data)
        for path in deletes:
            path.unlink(missing_ok=True)
        verify_runtime(project, commit)
    except Exception:
        for path, data in before.items():
            if data is None:
                path.unlink(missing_ok=True)
            else:
                atomic_write(path, data)
        raise
    return {**record, "dest_files": ["res://" + PUBLIC_ROOT + name for name in files]}


def verify_runtime(project: Path, commit: str) -> dict:
    record = json.loads(safe_path(project, INVENTORY).read_text())
    root, files = committed_runtime(safe_path(project, ".plugged/rookframe-ui-kit"), commit)
    if record["commit"] != commit or record["sourceRoot"] != root or record["files"] != hashes(files):
        raise ValueError("UI Kit ownership inventory does not match the selected revision.")
    for name, data in files.items():
        if safe_path(project, PUBLIC_ROOT + name).read_bytes() != data:
            raise ValueError("UI Kit verification failed: " + name)
    return record


def write_provenance(project: Path, selection: dict[str, str], application: bool = False) -> dict:
    record = verify_runtime(project, selection["commit"])
    provenance = {"schemaVersion": 2, "source": "rookframe/rookframe-ui-kit",
                  "version": selection["tag"], "commit": selection["commit"],
                  "sourceRoot": record["sourceRoot"], "canonicalPublicRoot": "res://rookframe/ui/",
                  "materialization": {"tool": "rookframe-ui-kit-layout-adapter",
                                      "configuration": "res://plug.gd",
                                      "ownership": INVENTORY}}
    if application:
        provenance.update(applicationRoot="res://rookframe/application/", applicationUiRoot="res://rookframe/application/ui/")
    atomic_write(safe_path(project, PROVENANCE), encoded(provenance))
    return provenance


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("install", "verify"))
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--previous-commit", default="")
    parser.add_argument("--legacy-files-json", type=Path)
    parser.add_argument("--application", action="store_true")
    args = parser.parse_args()
    selection = {"tag": args.version, "commit": args.commit}
    try:
        legacy_files = json.loads(args.legacy_files_json.read_text(encoding="utf-8")) if args.legacy_files_json else None
        result = (install_runtime(args.project, selection, previous_commit=args.previous_commit,
                                  legacy_files=legacy_files) if args.action == "install"
                  else write_provenance(args.project, selection, args.application))
        print(json.dumps(result))
        return 0
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=__import__("sys").stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
