# Airtime — plan

`BAND` H1 ✓ · H2 nu · H3 · H4 · H5 · H6 · H7

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

## H6 — Fler hopptyper: elasticitet och sidor

Tre nya sorter bredvid CMJ (händer på höfterna) och CMJ med armsving, mätta
på samma sätt ur tiden i luften (METOD M1, M5):

| Sort | Utförande |
| --- | --- |
| **Squat jump (SJ)** | Händerna på höfterna. Gå ned till ~90° i knät, stå **stilla i 2–3 s**, hoppa utan att sjunka först. Sjunker man innan är hoppet ogiltigt (syns i videon). |
| **Enbens-CMJ vänster** | Händerna på höfterna, nedgång och hopp på vänster ben, landa på samma ben med rakt knä. |
| **Enbens-CMJ höger** | Samma på höger ben. |

**Testdagen** (cirka 12 min, samma ordning varje gång): 5 min uppvärmning, 2
provhopp, sedan 3 CMJ · 3 SJ · 3 vänster · 3 höger med växlade ben, 1 min
vila mellan sorterna. Ett hopp per video, eller flera hopp i samma video
(appen sparar flera markeringar ur en video).

**Det som räknas ut (bästa hoppet per sort och dag):**

- **Elasticiteten, EUR = CMJ-höjd / SJ-höjd.** Visar hur mycket sträck-och-
  studs i musklerna tillför. Nära 1,0 betyder att nedgången ger lite; omkring
  1,1 eller mer att den ger mycket. Källa och gränser blir METOD M8.
- **Sidskillnaden = (starkare − svagare) / starkare**, på höjden i enbens-CMJ.
  Flaggas över 15 % (METOD M9, antagande som kalibreras). Kopplas till swayen
  och bakre höften, där en svagare sida är misstänkt.

**Visningen:** startsidan får ett kort för testdagen med CMJ, SJ, EUR och
vänster/höger med sidskillnaden. Diagrammet väljer sort som i dag, plus EUR
och sidskillnaden över tid.

**Klart när:** sorterna sparas och läses tillbaka bredvid gamla filer (gamla
JSON-filer går att läsa), EUR och sidskillnaden räknas mot facit i tester, och
testdagens kort visas på telefonen.

## H7 — Kastets fart: rotationskastet med medicinboll

Det golfspecifika testet för kraftöverföringen. TPI:s kulstötning
(boll 2,7 kg, METOD M3) med vårt tillägg knästående mot stående, och med
**bollens fart** mätt ur videon i stället för bara längden.

**Sorter (per sida):**

| Sort | Utförande |
| --- | --- |
| **Stående** | Golfställning vinkelrätt mot kastriktningen, bollen vid bröstet. Rotera och stöt ut som i svingen; stanna på främre benet, kliv inte förbi främre foten (TPI). |
| **Knästående** | Båda knäna i en matta, höften rakt över knäna. Samma rotation och stöt. Benen kan inte hjälpa till. |

Båda sidor: **golfsidan** (åt samma håll som svingen) är huvudmåttet, och
motsatt sida visar balansen. 3 kast per sort, bästa räknas.

**Filmningen:** telefonen på ett stativ eller mot en vägg **vinkelrätt mot
kastriktningen**, 4–5 m bort, i höjd med bröstet, 240 bilder/s. Hela kastet
och de första ~0,5 m efter släppet ska synas.

**Mätningen (METOD M10):** bollen själv är måttstocken, så ingen kalibrering
behövs. I videon markerar man:

1. bollens **kanter** i en bild strax efter släppet (ger diametern i pixlar),
2. bollens **mitt** i två bilder efter släppet, cirka 15–20 bilder isär
   (60–80 ms vid 240 bilder/s).

Farten = sträckan i pixlar / diametern i pixlar × bollens diameter (mätt en
gång med måttband, sparas) / tiden mellan bilderna. Den räknas vid mitten av
intervallet. Kastet ska gå i bildens plan; ett snett kast ger för låg fart.
Längden kan skrivas in för hand som ett extra mått, för jämförelse med TPI.

**Det som räknas ut:**

- **Bollens fart** i m/s och km/h, per sort och sida.
- **Benens bidrag = stående / knästående − 1.** Litet bidrag stödjer
  hypotesen att kraften inte förs över från benen (METOD M11, eget mått utan
  normer, följs över tid).
- **Sidbalansen** golfsidan mot motsatt sida.

**Klart när:** farten räknas mot facit i tester (påhittade punkter med känt
svar), markeringen fungerar på telefonen, och ett kast mätt i appen stämmer
med en hand-räkning ur samma video inom 5 %.
