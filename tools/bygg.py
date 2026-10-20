"""TestFlight-bygget: vad nästa bygge bär, och starten när Johannes sagt ja.

    python tools/bygg.py            # vad nästa bygge bär, och om det kan starta; startar inget
    python tools/bygg.py --starta   # starta ios-testflight på main (bara efter Johannes ja)

Samma regler som Idunn (arbetssättet, Bygget och leveransen): högst ett bygge
per dag (svensk tid), bara när Actions är grönt för main:s senaste commit
(grenen `ci-resultat`), inget annat bygge igång hos Codemagic för någon app,
och minuter kvar (`tools/arbetssatt/codemagic_vakt.py`). Startas aldrig med en tagg.

Token: CODEMAGIC_API_TOKEN i C:\\dev\\golf-sg\\.env. Den skrivs aldrig ut.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "arbetssatt"))
import codemagic_vakt as cm  # noqa: E402

API = "https://api.codemagic.io/builds"
# Codemagic-appens id. Sätts när appen lagts till i Codemagic (README, "Första gången").
APP_ID = ""
WORKFLOW = "ios-testflight"
# Det som startar Actions (`paths` i .github/workflows/test.yml). En commit som bara rör annat får inget resultat.
CI_SOKVAGAR = ("HoppKit/", "App/", "tools/", "docs/", "project.yml", ".github/workflows/test.yml")


def git(*a: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *a], capture_output=True, text=True, encoding="utf-8")


def utan_ci(filer: list[str]) -> bool:
    """Startar inget av det här Actions?"""
    return not any(f == p or f.startswith(p) for f in filer for p in CI_SOKVAGAR)


def ci_gront(sammanfattning: str | None) -> bool:
    rader = (sammanfattning or "").splitlines()
    swift = [r for r in rader if r.startswith(("GRÖNT", "RÖTT"))]
    return bool(swift) and all(r.startswith("GRÖNT") for r in swift)


def ci_resultat(gren: str) -> tuple[str, str | None]:
    """(sha, sammanfattning eller None) för grenens senaste commit, ur grenen ci-resultat. Saknar den senaste
    commiten resultat används närmaste äldre commit med resultat, men bara om allt ändrat efter den ligger
    utanför CI_SOKVAGAR."""
    rad = git("ls-remote", "origin", f"refs/heads/{gren}").stdout.split()
    if not rad:
        raise SystemExit(f"Grenen {gren!r} finns inte på origin. Inget startat.")
    sha = rad[0]
    git("fetch", "-q", "origin", gren)
    git("fetch", "-q", "origin", "ci-resultat")
    resultat = git("rev-parse", "FETCH_HEAD").stdout.strip()
    for c in git("rev-list", "--first-parent", "-n", "30", sha).stdout.split():
        r = git("show", f"{resultat}:resultat/{c}.txt")
        if r.returncode == 0:
            andrat = git("diff", "--name-only", c, sha).stdout.split()
            return sha, (r.stdout if c == sha or utan_ci(andrat) else None)
    return sha, None


def hinder(alla: list[dict], nu: datetime, ci: str | None, betalt: bool = False,
           igen: bool = False) -> list[str]:
    """Det som stoppar ett bygge just nu; tom lista när det kan starta."""
    ut: list[str] = []
    if not APP_ID:
        ut.append("APP_ID saknas i tools/bygg.py: appen är inte tillagd i Codemagic än")
    if not ci_gront(ci):
        ut.append("Actions är inte grönt för main:s senaste commit" if ci else
                  "Actions har inget resultat för main:s senaste commit än")
    return ut + cm.hinder(alla, nu, APP_ID, WORKFLOW, betalt=betalt, igen_idag=igen)


def senaste_bygget(alla: list[dict]) -> dict | None:
    klara = [b for b in alla if b.get("appId") == APP_ID and cm.arbetsflode(b) == WORKFLOW
             and b.get("status") == "finished"]
    return max(klara, key=lambda b: b.get("startedAt") or "", default=None)


def innehall(fran: str | None) -> list[str]:
    """Commits på origin/main sedan `fran` (förra byggets commit), nyast först."""
    git("fetch", "-q", "origin", "main")
    spann = f"{fran}..origin/main" if fran else "origin/main"
    return git("log", "--oneline", "--no-decorate", "-n", "40", spann).stdout.splitlines()


def starta(tok: str) -> str:
    req = urllib.request.Request(API, method="POST", data=json.dumps(
        {"appId": APP_ID, "workflowId": WORKFLOW, "branch": "main"}).encode())
    req.add_header("x-auth-token", tok)
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "hopp-bygg/1.0")
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            svar = json.load(r)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"Codemagic svarade {e.code}: {e.read().decode('utf-8', 'replace')[:300]}")
    bygg_id = svar.get("buildId")
    if not bygg_id:
        raise SystemExit(f"Inget buildId i svaret, inget startat: {svar}")
    return bygg_id


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--starta", action="store_true", help="starta bygget (bara efter Johannes ja)")
    ap.add_argument("--betalt", action="store_true",
                    help="minuterna får ta slut: Johannes har slagit på betalning i Codemagic")
    ap.add_argument("--igen-idag", action="store_true",
                    help="ett andra bygge i dag (bara när Johannes uttryckligen ber om det)")
    a = ap.parse_args()
    tok = cm.token()
    nu = datetime.now(timezone.utc)
    alla = cm.hamta(tok, nu)
    forra = senaste_bygget(alla)
    fran = ((forra or {}).get("commit") or {}).get("hash")
    sha, ci = ci_resultat("main")

    print(f"Förra bygget: nummer {(forra or {}).get('index', '?')} från {fran[:7] if fran else '?'}")
    rader = innehall(fran)
    print(f"Nästa bygge från main {sha[:7]} bär {len(rader)} commits:")
    for r in rader:
        print("  " + r)
    print(f"Codemagic: {cm.kvar(alla, nu)} min kvar den här månaden, "
          f"bygget skattas till {cm.skatta(alla, WORKFLOW, APP_ID)} min.")
    stopp = hinder(alla, nu, ci, a.betalt, a.igen_idag)
    for s in stopp:
        print("STOPP: " + s)
    if not a.starta:
        return 0 if not stopp else 1
    if stopp or not rader:
        raise SystemExit("Inget startat.")
    print(f"ios-testflight startat: https://codemagic.io/app/{APP_ID}/build/{starta(tok)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
