# Airtime — plan

`BAND` H1 ✓ · H2 nu · H3 · H4 · H5

Mål: mäta CMJ med bara telefonen, lika exakt som My Jump, och följa impulsen
och dagsformen över vintern (vinterträningen 2026/27).

## H1 — Logiken (AirtimeKit)

Tiden i luften ur videons bildtider, höjd, avstampsfart, impuls, effekt,
osäkerheten för en bild, historiken som fil, dagarna och dagsformen.

**Klart när:** `swift test` är grönt i Actions, med facit räknat utanför koden.

## H2 — Appskalet

Inspelning i högsta bildfrekvens (upp till 240), video ur Bilder (originalet),
stega bild för bild, markera första bilden i luften och första på marken, spara
med sort (händer på höfterna eller armsving) och vikt. Historik per dag, diagram
över höjd, impuls och effekt, och dagsformen.

**Klart när:** H3:s bygge går igenom och Johannes har mätt ett hopp på telefonen.

## H3 — Första bygget

Johannes del (README, "Första gången"): repot i Codemagic, appen i App Store
Connect och signeringen. Sedan `python tools/bygg.py --starta` efter ett ja.

**Klart när:** bygget ligger i TestFlight.

## H4 — Facit

5–10 hopp, filmade i 240 bilder/s, där Johannes räknar bilderna själv. De är
facit för H5.

**Klart när:** facit finns och appens markering stämmer med räkningen inom en bild.

## H5 — Automatisk avläsning

Johannes drar en ruta runt fötterna, och appen hittar avstamp och landning ur
hur pixlarna i rutan ändras (BESLUT B3). Johannes bekräftar bara. Metoden tas
fram och prövas på facitvideorna innan den byggs in.

**Klart när:** avläsningen träffar facit inom en bild på minst 9 av 10 hopp.
