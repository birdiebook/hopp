"""Vid sessionsstart: är arbetssättet i det här repot aktuellt och orört?

Kopia från det privata repot birdiebook/arbetssatt (synka.py). Skriptet läser
`.claude/arbetssatt.json` (versionen och filernas hashar när de synkades), och
säger till om (1) en kopierad fil har ändrats här i stället för i arbetssatt,
eller (2) arbetssatt har gått vidare sedan synken. Det tystnar när arbetssatt
inte går att nå (molnsessioner når bara sitt eget repo) och avslutar alltid
med 0, så att en session aldrig stoppas av det.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = "https://github.com/birdiebook/arbetssatt.git"


def hash_utan_radslut(innehall: bytes) -> str:
    """Radslut räknas inte: en Windows-checkout har CRLF där molnet har LF."""
    return hashlib.sha256(innehall.replace(b"\r\n", b"\n")).hexdigest()


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # Windows skriver annars cp1252 till hooken
    rot = Path(__file__).resolve().parents[1]
    las = rot / ".claude" / "arbetssatt.json"
    if not las.exists():
        return 0
    data = json.loads(las.read_text(encoding="utf-8"))
    andrade = [rel for rel, h in data.get("filer", {}).items()
               if (rot / rel).exists() and hash_utan_radslut((rot / rel).read_bytes()) != h]
    if andrade:
        print("Arbetssättet: de här kopiorna har ändrats här i stället för i birdiebook/arbetssatt, "
              "och skrivs över vid nästa synk: " + ", ".join(andrade))
    try:
        r = subprocess.run(["git", "ls-remote", REPO, "refs/heads/main"], capture_output=True, text=True,
                           timeout=8, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
    except (OSError, subprocess.SubprocessError):
        return 0
    senaste = r.stdout.split()[0] if r.returncode == 0 and r.stdout.strip() else None
    if senaste and senaste != data.get("version"):
        print(f"Arbetssättet i det här repot ({data.get('version', '?')[:7]}) är äldre än "
              f"birdiebook/arbetssatt ({senaste[:7]}). Synka från hemdatorn: "
              f"python C:\\dev\\arbetssatt\\synka.py {rot}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # noqa: BLE001 — en kontroll vid start får aldrig stoppa sessionen
        sys.exit(0)
