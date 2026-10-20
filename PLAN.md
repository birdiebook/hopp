# Airtime — plan

`BAND` H1 ✓ · H2 nu · H3 · H4 · H5 · H6 · H7 · H8 · H9

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
| **Enbens-CMJ vänster** | Händerna på höfterna, nedgång och hopp på vänster ben. |
| **Enbens-CMJ höger** | Samma på höger ben. |

Enbenshoppen har **två landningar**, valda vid sparandet: på samma ben med
rakt knä (stämmer bäst med måttet), eller på båda fötterna med raka ben
(enklare). De sparas som olika varianter och jämförs bara med sig själva
(BESLUT B10).

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

Båda sidor, sparade som **mot vänster** och **mot höger**. Inställningen
**spelar höger/vänster** avgör vilken som är golfsidan (åt samma håll som
svingen), så att appen fungerar för båda (BESLUT B11). Golfsidan är
huvudmåttet, och motsatt sida visar balansen. 3 kast per sort, bästa räknas.

**Filmningen:** telefonen på ett stativ eller mot en vägg **vinkelrätt mot
kastriktningen**, 4–5 m bort, i höjd med bröstet, 240 bilder/s. Hela kastet
och de första ~0,5 m efter släppet ska synas.

**Mätningen (METOD M10):** bollen själv är måttstocken, så ingen kalibrering
behövs. I videon markerar man:

1. bollens **kanter** i en bild strax efter släppet (ger diametern i pixlar),
2. bollens **mitt** i två bilder efter släppet, cirka 15–20 bilder isär
   (60–80 ms vid 240 bilder/s).

Farten = sträckan i pixlar / skalan i pixlar × skalans verkliga längd /
tiden mellan bilderna. **Skalan** väljs, och den senaste sparas (BESLUT B12):

- **bollens diameter**, mätt en gång med måttband;
- **en känd längd i videon**: två punkter och längden, till exempel lådan på
  60 cm eller en tejpbit på golvet;
- **kroppslängden**: huvud och fötter i en bild där man står rakt, med
  längden ur inställningarna.

Bollen och skalan ska stå ungefär lika långt från kameran, annars blir farten
fel i proportion till avståndet. Den räknas vid mitten av
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

**Sedan, som H5 för hoppen:** appen hittar bollen själv. Man pekar ut den i en
bild, och appen följer den genom bilderna och mäter diametern i pixlar. Man
bekräftar bara. Metoden tas fram på Johannes kastvideor innan den byggs in
(samma princip som BESLUT B3).

## Ordningen efter första bygget

H6 (små tillägg i logiken) → H7 (ny markering) → H9 (samma videor, ingen ny
utrustning) → H8 (kräver ett midjebälte och en andra kamera för valideringen).

## H8 — Hopp med telefonens rörelsesensor: hur snabbt, inte bara hur högt

Telefonen sitter på kroppen och mäter accelerationen genom hela hoppet. Det ger
kraftkurvan över tid och därmed det som tiden i luften inte kan visa: hur fort
kraften byggs upp.

**Utförande:** telefonen i ett tajt löparbälte **över korsryggen**, stående på
höjden (nära tyngdpunkten), händerna på höfterna som vanligt. Appen leder med
ljud eftersom skärmen inte syns: "stå still" → pip efter 2 s stillhet → hoppa →
stå still efter landningen → pip när hoppet är sparat. Flera hopp i rad i samma
pass.

**Mätningen (METOD M12):**

- Rörelsedatan läses i högsta takt telefonen ger (CoreMotion, troligen 100 Hz;
  den verkliga takten mäts ur tidsstämplarna). Den lodräta accelerationen fås
  genom att projicera accelerationen på tyngdkraftens riktning, i varje prov.
- **Stillastående före** (minst 1 s) ger nollnivån och bruset. Rörelsen börjar
  när accelerationen lämnar bruset (5 standardavvikelser), med 30 ms bakåt.
- **Avstampet** är när telefonen går in i fritt fall (accelerationen ≈ −g),
  **landningen** när den lämnar det. Det ger en egen tid i luften att jämföra
  med videon.
- Kraften F = m · (g + a) med vikten ur inställningarna. Farten fås genom att
  integrera accelerationen från rörelsens start; sträckan genom att integrera
  en gång till (kort tid, så driften är liten).

**Det som räknas ut:**

| Mått | Vad det säger för golfen |
| --- | --- |
| **Tid till avstamp** | Hur snabbt hela rörelsen går |
| **RSI-mod = höjden / tiden till avstamp** | Explosiviteten. Det mått som ligger närmast svingens tempo |
| **Avstampsfart och impuls** | Samma som i videon, nu ur kraften (kontroll mot M3) |
| **Toppkraft och toppeffekt** (F · v) | Effekten mätt, inte uppskattad som med Sayers (M4) |
| **Nedgångens djup och tid, bromsfas och skjutfas** | Hur hoppet görs: djupt och långsamt eller grunt och snabbt |

Visningen: kraftkurvan efter varje hopp, med faserna markerade, och RSI-mod
över tid.

**Validering innan måtten visas:** 10 hopp med telefonen i bältet och samtidigt
filmade i slow motion med en annan kamera (en annan telefon eller iPad).

**Klart när:** uträkningen ger facit ur påhittade hopp med känd kraftkurva
(tester), sensorns tid i luften ligger inom 20 ms från videons på 9 av 10
valideringshopp, och avstampsfarten inom 5 %. Annars visas bara sensorns tid
till avstamp och RSI-mod med videons höjd, och resten skrivs som ett fynd.

## H9 — Kroppens rörelse ur videon

Apples kroppsigenkänning (Vision, kroppens punkter i varje bild: höft, knä,
fotled, axel med flera) körs på samma video som tiden i luften mäts ur. Den
behöver ingen ny utrustning.

**Det den ger:**

1. **Landningskontroll.** Knävinkeln vid avstampet jämförs med knävinkeln vid
   landningen. Är landningen tydligt mer böjd (mer än 10°) varnar appen för att
   höjden blir för hög (METOD M1). Det gör alla andra mått säkrare.
2. **Nedgången:** djupast knävinkel och höftens lägsta läge i cm (skalan ur
   kroppslängden), och tiden ned och upp. Det ger **tid till avstamp och
   RSI-mod ur videon**, utan sensor (som H8, men grövre).
3. **SJ-kontrollen:** sjunker höften mer än 2 cm innan uppåtrörelsen i ett
   squat jump är hoppet ogiltigt (H6).
4. **Avstamp och landning automatiskt** ur fotledernas rörelse, som ett andra
   förslag bredvid H5:s ruta runt fötterna.

**Utanför H9 (kanske senare):** knäna inåt i enbenshoppet (kräver filmning
framifrån) och höftens och axlarnas rotation i kastet (kräver 3D, osäkert ur
en kamera).

**Mätningen (METOD M13):** punkterna jämnas ut över tid innan vinklar räknas,
eftersom de skakar vid snabb rörelse och rörelseoskärpa. Vision körs bara på
telefonen; uträkningen ur punkterna ligger i AirtimeKit och testas på Linux med
påhittade punktserier. För att pröva metoden på riktiga hopp kan appen
exportera punkterna (inte videon) när Johannes själv väljer det (Dataregeln).

**Klart när:** knävinkeln stämmer med en hand-mätning i videon inom ±5° i 10
bilder, nedgångens djup inom ±3 cm, och tiden till avstamp inom 2 bilder,
på minst 5 hopp.
