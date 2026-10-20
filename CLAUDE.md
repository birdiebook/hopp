# Airtime — arbetssätt

Airtime är en privat iPhone-app som mäter hopp (CMJ) ur slow motion: tiden i luften
ger höjd, avstampsfart, impuls och effekt. Den hör till Johannes vinterträning
för golf, och impulsen är måttet som följer klubbhastigheten (docs/METOD.md M3).

## Dataregeln — läs först

**Videor och mätningar lämnar bara telefonen när Johannes själv skickar dem.**

- Appen har ingen server och inget moln. Historiken ligger som JSON i appens
  Application Support, och videorna bredvid (utanför iCloud-backupen).
- Testerna bär **påhittade** hopp. Lägg aldrig in riktiga mätningar eller videor
  i repot: `.gitignore` stänger ute `*.mov`, `*.mp4`, `*.csv` och `data/`.
- En video eller ett värde som Johannes själv delar i chatten får analyseras,
  men går aldrig vidare in i repot, testerna eller commit-meddelanden.

## Arbetssättet — delat med de andra apparna

Det som gäller fler än en app (bygget, minuterna, testerna, datan) står i skillen
`.claude/skills/arbetssatt/`, med verktygen i `tools/arbetssatt/`. Båda är kopior
från `birdiebook/arbetssatt`: ändra där och synka, aldrig i kopian.

## Bygget — ingen Mac

- **Logiken bor i `AirtimeKit/`** (Swift-paket, bara Foundation) och testas på Linux
  i GitHub Actions (`swift:6.1`, release med `-enable-testing`). Det är den enda
  kompilatorn före TestFlight-bygget: **pusha och läs resultatet** innan du tror att
  Swift-kod fungerar: `git fetch origin ci-resultat && git show
  origin/ci-resultat:resultat/<sha>.txt`.
- **Appen i `App/` är ett tunt SwiftUI-skal.** Xcode-projektet genereras ur
  `project.yml` (XcodeGen) och är gitignorerat, liksom `App/Info.plist`.
- **TestFlight** byggs i GitHub Actions (`.github/workflows/testflight.yml`,
  BESLUT B9), gratis eftersom repot är publikt. Bundle-id `se.birdiebook.airtime`.
  Bygget startas **bara för hand** ("Run workflow", eller `run_workflow` via
  GitHub-API:t), efter Johannes ja, högst ett per dag. Aldrig med en tagg eller
  push. `codemagic.yaml` och `tools/bygg.py` är vägen via Codemagic, som står
  tills dess minuter fylls på.
- App-koden kompileras först i TestFlight-bygget, så ett fel där kostar ett bygge.
  Läs igenom App/-ändringar extra noga mot API:ernas signaturer före push.

## Beslut och metod

- **`docs/BESLUT.md`** — varje beslut: valt, bortvalt, kostnad, när det omprövas.
- **`docs/METOD.md`** — varje formel och konstant med källa och källans status.
  Koden hänvisar med `// METOD M3` och `// BESLUT B2`; `tools/kolla_metod.py`
  (i Actions) fäller en hänvisning utan rubrik.

## Planen

Etapper och "Klart när" står i [PLAN.md](PLAN.md), med bandet överst. Byt markör
i bandet i samma commit som en etapp landar.

## Svaren

Korta och direkta: slutsats och nästa steg först.
