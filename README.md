# Airtime

Mäter hopp (CMJ) ur slow motion med bara telefonen: höjd, impuls och effekt,
och dagsformen över tid. Se [PLAN.md](PLAN.md) och [CLAUDE.md](CLAUDE.md).

## Första gången (Johannes, cirka 20 min)

1. **App Store Connect → Appar → +:** ny app, bundle-id `se.birdiebook.airtime`
   (registreras annars av första bygget), namnet "Airtime – Jump Test" eller liknande (namnet i App Store måste vara unikt; hemskärmen visar "Airtime").
   Lägg till den interna testgruppen med automatisk distribution, som för Idunn.
2. **GitHub → birdiebook/hopp → Settings → Secrets and variables → Actions:**
   fyra hemligheter (BESLUT B9):
   - `APP_STORE_CONNECT_ISSUER_ID` och `APP_STORE_CONNECT_KEY_IDENTIFIER`: från
     App Store Connect → Users and Access → Integrations → App Store Connect API.
   - `APP_STORE_CONNECT_PRIVATE_KEY`: hela innehållet i nyckelns `.p8`-fil.
   - `CERTIFICATE_PRIVATE_KEY`: samma base64-nyckel som Idunn har i Codemagic.

Sedan: Actions → testflight → Run workflow, efter ett ja.
