# Airtime

Mäter hopp (CMJ) ur slow motion med bara telefonen: höjd, impuls och effekt,
och dagsformen över tid. Se [PLAN.md](PLAN.md) och [CLAUDE.md](CLAUDE.md).

## Första gången (Johannes, cirka 20 min)

1. **App Store Connect → Appar → +:** ny app, bundle-id `se.birdiebook.airtime`
   (registreras annars av första bygget), namnet "Airtime – Jump Test" eller liknande (namnet i App Store måste vara unikt; hemskärmen visar "Airtime").
   Lägg till den interna testgruppen med automatisk distribution, som för Idunn.
2. **Codemagic → Add application:** välj repot `birdiebook/hopp`. Läs repot med
   en deploy key (SSH, bara läsrätt), som för Idunn: en app som läggs till med
   https-adress kan inte läsa ett privat repo.
3. **Codemagic → appen → Environment variables:** gruppen `signing` med
   `CERTIFICATE_PRIVATE_KEY` (base64 av samma `cert_key.pem` som Idunn).
4. Skriv Codemagic-appens id i `tools/bygg.py` (`APP_ID`), eller be Claude göra det.

Sedan: `python tools/bygg.py` visar vad bygget bär, och `--starta` startar det.
