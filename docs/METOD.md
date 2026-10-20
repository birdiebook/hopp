# Metod och källor

Varje formel och konstant i Hopp, med varifrån den kommer. Koden hänvisar hit
(`// METOD M3`), och en konstant utan rad här är en bugg.

**Källans status:** **mätt** (i det här projektet) · **standard** · **fysik** ·
**forskning** ("ej läst i original" = bara hänvisningen är kontrollerad,
"sammanfattning läst" = bara abstract eller sammanfattning) · **antagande**
(ska kalibreras).

---

## M1 — Höjden ur tiden i luften

- h = g·t²/8, med g = 9,81 m/s². **fysik:** kroppen lämnar marken med farten
  v och är i luften i t = 2v/g.
- Metoden att mäta CMJ ur tiden i luften: Bosco, Luhtanen & Komi 1983, *A simple
  method for measurement of mechanical power in jumping*, Eur J Appl Physiol
  50:273–282. **forskning, ej läst i original.**
- Förutsätter att kroppen har samma läge vid avstamp och landning: raka ben och
  tår vid landningen. Landar man med böjda knän blir höjden för hög.
- CMJ med händerna på höfterna är standarden i forskningen, eftersom armarna
  annars bidrar. **standard** (praxis i litteraturen).

## M2 — Avstampsfarten

- v = g·t/2. **fysik.**

## M3 — Impulsen

- Nettoimpuls = massa × avstampsfart (N·s). **fysik** (impuls = ändring av rörelsemängd).
- Wells m.fl. 2022, *Relationships between highly skilled golfers' clubhead
  velocity and kinetic variables during a countermovement jump*, Sports
  Biomechanics 23(12):2598–2610: hos 50 skickliga golfare hängde klubbhastigheten
  ihop med positiv impuls (r = 0,695) och nettoimpuls (r = 0,689), men inte med
  hopphöjden. Författarna föreslår avstampsfart × massa som fältmått.
  **forskning, sammanfattning läst.**
- Challenge Tour-golfare (31 st, 2019, PubMed 30572804): positiv impuls i CMJ
  r = 0,616 mot klubbhastigheten. **forskning, sammanfattning läst.**
- Förbehåll: kraftplattans positiva impuls är inte exakt samma sak som
  nettoimpulsen här. Den följer samma sak, men talen går inte att jämföra rakt av.

## M4 — Effekten

- Toppeffekt (W) = 60,7 · h(cm) + 45,3 · massa(kg) − 2055. Sayers m.fl. 1999,
  *Cross-validation of three jump power equations*, Med Sci Sports Exerc
  31(4):572–577. **forskning, ej läst i original.** Ekvationen är framtagen på
  squat jump men används brett för CMJ. Se den som en uppskattning.

## M5 — Markeringen och bildtiderna

- Användaren markerar **första bilden i luften** och **första bilden på marken
  igen**. Då ligger både det verkliga avstampet och den verkliga landningen
  inom bilden före markeringen, och felen tar ut varandra i snitt. Samma princip
  som My Jump, validerad mot kraftplatta: Balsalobre-Fernández, Glaister &
  Lockey 2015, J Sports Sci 33(15):1574–1579. **forskning, ej läst i original.**
- Tiden räknas ur **bildernas tider i filen**, inte ur en nominell bildfrekvens,
  eftersom iPhone-video kan ha ojämn takt. **antagande** om att filens tider
  är rätt; prövas mot facit i PLAN.md H4.
- Osäkerheten för en bild: dh ≈ g·t·dt/4. Vid 240 bilder/s och 0,7 s i luften
  är det ±0,7 cm, vid 60 bilder/s ±2,9 cm. **fysik** (derivatan av M1).
- Gränser: 0,15–1,0 s i luften (3 cm–1,23 m). Utanför är markeringen fel, eller
  så är videon en slow motion som sparats om till 30 bilder/s med nedsaktningen
  inbakad, så att tiden blir ungefär 8 gånger för lång. **antagande.** Videor ur
  Bilder hämtas därför som original (`preferredItemEncoding: .current`).

## M6 — Dagsformen

- Dagens **snitthöjd** jämförs med medianen av upp till 5 tidigare dagars
  snitthöjd, för samma sort av hopp. Minst 3 tidigare dagar krävs. Flaggan
  "kör lättare" sätts vid 5 % lägre eller mer.
- Claudino m.fl. 2017, *The countermovement jump to monitor neuromuscular
  status: A meta-analysis*, J Sci Med Sport 20(4):397–402: snittet av hoppen är
  ett känsligare mått på trötthet än det bästa hoppet. **forskning, ej läst i
  original.**
- 5 %-gränsen, 5 dagar och 3 dagar är **antaganden**. De ska kalibreras mot
  grundarens egen variation mellan dagar när det finns ett par veckors data.

## M7 — Kameran

- Bakre vidvinkelkameran i det format som har högst bildfrekvens (upp till 240),
  och vid lika den största bilden upp till 1080p. Bildstabiliseringen är av,
  eftersom den beskär och kan förskjuta bilderna. **antagande.**
