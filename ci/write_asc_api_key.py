#!/usr/bin/env python3
"""Materialize the App Store Connect API key from GitHub Actions secrets.

Expected environment:
  APP_STORE_CONNECT_API_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_API_KEY_P8   # PEM body; literal \\n is OK
"""

from __future__ import annotations

import os
import stat
import sys
from pathlib import Path


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.stderr.write(f"error: {name} is not set\n")
        raise SystemExit(1)
    return value


def normalize_pem(raw: str) -> str:
    text = raw.replace("\r\n", "\n").replace("\r", "\n")
    if "\\n" in text and "-----BEGIN" in text:
        text = text.replace("\\n", "\n")
    if not text.endswith("\n"):
        text += "\n"
    return text


def write_key(path: Path, pem: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(pem, encoding="utf-8")
    path.chmod(stat.S_IRUSR | stat.S_IWUSR)


def main() -> int:
    key_id = require_env("APP_STORE_CONNECT_API_KEY_ID")
    issuer_id = require_env("APP_STORE_CONNECT_ISSUER_ID")
    pem = normalize_pem(require_env("APP_STORE_CONNECT_API_KEY_P8"))

    filename = f"AuthKey_{key_id}.p8"
    destinations = [
        Path.home() / "private_keys" / filename,
        Path.home() / ".private_keys" / filename,
        Path.home() / ".appstoreconnect" / "private_keys" / filename,
        Path("private_keys") / filename,
    ]
    for dest in destinations:
        write_key(dest, pem)
        print(f"Wrote {dest}")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            handle.write(f"key_id={key_id}\n")
            handle.write(f"issuer_id={issuer_id}\n")
            handle.write(f"key_path={destinations[0]}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
