#!/usr/bin/env python3
from pathlib import Path
import os
import shutil
import subprocess
import sys


ROOT = Path("/Users/ar/Projects/Taglauncher")
RUNTIME = Path("/Users/ar/.cache/codex-runtimes/codex-primary-runtime/dependencies")
NODE = RUNTIME / "node/bin/node"
NODE_MODULES = RUNTIME / "node/node_modules"
SCRIPT = ROOT / "Docs/X-Op资料/Screenshots/render_marketing_screenshots.mjs"


def main() -> int:
    node = str(NODE) if NODE.exists() else shutil.which("node")
    if not node:
        print("Node.js is required to render localized marketing screenshots.", file=sys.stderr)
        return 1

    env = os.environ.copy()
    existing = env.get("NODE_PATH")
    env["NODE_PATH"] = str(NODE_MODULES) if not existing else f"{NODE_MODULES}{os.pathsep}{existing}"

    completed = subprocess.run([node, str(SCRIPT)], cwd=str(ROOT), env=env)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
