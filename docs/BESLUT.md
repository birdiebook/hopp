# Beslut och avvägningar

Varje beslut som formar bygget. Nytt beslut = ny rad i samma commit som koden.
Ändras ett beslut skrivs det om här (git minns det gamla).

Status: **gäller** · **prövas** (gäller tills en mätning avgör) · **ersatt**.

## B1 — En egen app, inte en del av Birdiebook
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** appen Airtime (BESLUT B8) med eget repo och eget App Store Connect-konto.
- **Bortvalt:** ett gymverktyg i golfappen, som hade haft byggkedjan klar.
- **Kostnad:** en app till att sätta upp i Codemagic och App Store Connect.

## B2 — Ingen Mac: logiken på Linux, bygget hos Codemagic
*2026-10-20 · gäller · samma väg som Idunn*

- **Valt:** all räkning i `AirtimeKit` (bara Foundation), testad gratis i Actions.
  Appen är ett tunt skal som bara Codemagic kompilerar.
- **Kostnad:** ett fel i App/ syns först i ett bygge. Skalet hålls därför litet.

## B3 — Manuell markering först, automatisk sedan
*2026-10-20 · gäller*

- **Valt:** första bygget har bara manuell markering. Den automatiska
  avläsningen (pixeländring i en ruta runt fötterna) byggs när 5–10 facitvideor
  finns att kalibrera mot (PLAN.md H4–H5).
- **Bortvalt:** Apples kroppsigenkänning (Vision) direkt. Den ger fotleder, inte
  tår, och går inte att pröva utan Mac. Den är reserven om rutan inte räcker.
- **Omprövas:** om rutan missar mer än en bild på fler än 1 av 10 facithopp.

## B4 — Allt stannar på telefonen
*2026-10-20 · gäller*

- **Valt:** ingen server, inget moln, ingen inloggning. Historik och videor i
  appens mapp, videorna utanför iCloud-backupen.
- **Kostnad:** byter Johannes telefon följer historiken med bara via backupen;
  videorna gör det inte.

## B5 — Tiden i luften, inte låda eller vägg
*2026-10-20 · gäller*

- **Valt:** CMJ med händerna på höfterna, mätt ur tiden i luften (METOD M1, M5).
  Armsving sparas som en egen sort och jämförs aldrig med standardhoppet.
- **Bortvalt:** hopp mot låda (mäter hur högt fötterna dras upp, inte kroppen)
  och hopp-och-räck mot vägg (räckvidden och armarna ingår).

## B6 — Impulsen är huvudmåttet
*2026-10-20 · gäller*

- **Valt:** diagrammet visar höjd, impuls och effekt, men det är impulsen som
  följs för golfen (METOD M3). Dagsformen räknas på höjden (METOD M6).
- **Varför:** hos skickliga golfare följer klubbhastigheten impulsen bättre än
  höjden, och impulsen tar hänsyn till vikten.

## B7 — Repot är publikt
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** `birdiebook/hopp` är publikt, så att GitHub Actions är gratis utan
  gräns. Kontots 2 000 minuter för privata repon tog slut 18/10.
- **Kostnad:** vem som helst kan läsa koden. Repot får därför aldrig bära en
  e-postadress, en nyckel eller en mätning (CLAUDE.md, Dataregeln).

## B8 — Namnet är Airtime
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** Airtime, det appen mäter: tiden i luften. Hemskärmen visar "Airtime";
  i App Store Connect, där namnet måste vara unikt, ett längre namn som
  "Airtime – Jump Test". Bundle-id `se.birdiebook.airtime`, paketet `AirtimeKit`.
- **Behålls:** repot heter `hopp` (syns ingenstans), liksom grenen `ci-resultat`.
- **Bortvalt:** Hopp (svenskt), Liftoff, Vert, Hang Time.

## B9 — TestFlight byggs i GitHub Actions
*2026-10-20 · gäller · Codemagics minuter slut till 1 november*

- **Valt:** `.github/workflows/testflight.yml` på GitHubs macOS-maskin, som är
  gratis för ett publikt repo (B7). Samma steg och verktyg som `codemagic.yaml`
  (codemagic-cli-tools), med App Store Connect-nyckeln och signeringsnyckeln som
  repots Actions-hemligheter. Startas bara för hand, efter Johannes ja, högst ett
  bygge per dag.
- **Bortvalt:** vänta till 1 november, eller betala för Codemagic.
- **Kostnad:** inga Codemagic-minuter alls. Bygget tar troligen längre tid än på
  Codemagics M2.
- **Omprövas:** när Codemagics minuter fylls på. Kvarstår vägen här tas
  `codemagic.yaml` och `tools/bygg.py` bort, så att det bara finns en väg.

## B10 — Enbenshoppen har två landningar
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** landning på samma ben eller på båda fötterna, sparade som olika
  varianter som bara jämförs med sig själva.
- **Varför:** samma ben stämmer bäst med tiden i luften (METOD M1), båda
  fötterna är enklare att göra lika varje gång.

## B11 — Kastet sparas som mot vänster eller mot höger
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** sidan sparas som riktning, och inställningen spelar höger/vänster
  avgör vilken som är golfsidan. Appen fungerar då för båda.

## B12 — Kastets skala väljs: bollen, en känd längd eller kroppslängden
*2026-10-20 · gäller · Johannes beslut*

- **Valt:** tre sätt att få skalan, den senaste sparas. Ingen fast bolldiameter.
- **Sedan:** appen följer bollen själv (PLAN.md H7), men skalan i meter kräver
  fortfarande en av de tre.
