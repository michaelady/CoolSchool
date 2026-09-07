# CoolSchool

Kid-safe practice game for Swiss **Lehrplan 21**, Zyklus 1–2 (ages ≤ 10). Flutter **web** first: four short games, four languages, local stars only.

No accounts, ads, or paywalls.

## Live web URL

**https://michaelady.github.io/CoolSchool/**

GitHub Actions builds `main` and publishes the `gh-pages` branch. If that URL 404s, enable Pages once:

1. Repo **Settings → Pages**
2. Source: **Deploy from a branch**
3. Branch: `gh-pages` / `/ (root)`

Private repositories need GitHub Pro (or a public repo) for Pages.

## Run locally

```bash
flutter pub get
flutter test
flutter analyze --no-fatal-infos
flutter run -d chrome
```

Web release build (same flags as CI):

```bash
flutter build web --release --no-wasm-dry-run --base-href /CoolSchool/
```

Serve the output with any static server, for example:

```bash
python3 -m http.server 8080 --directory build/web
```

Android stays scaffolded for a later APK (`flutter build apk`).

## How to play

1. Home language chips: **DE / FR / EN / RO**.
2. Pick a game: **Addition**, **Subtraction**, **Counting** (how many?), or **Schulsprache** (word ↔ picture / listen & pick).
3. Pick a level. Level 1 is open; later levels unlock after at least one star on the previous level.
4. Each prompt is read aloud. Tap **Vorlesen** / **Lire** / **Read aloud** / **Citește** to hear it again.
5. Tap an answer. The localized banner (**Richtig!** / **Bravo !** / **Right!** / **Corect!**, or **Schade!** / **Presque !** / **Almost!** / **Aproape!**) stays about 1.6s. Correct / wrong SFX play unless mute is on.
6. A short **transition** whoosh plays between screens. A soft **next** pop plays after the hold when the next prompt appears. Level-complete uses the rising fanfare. Mute is sticky for the session.
7. Finish the short set to earn 1–3 stars, then **Home**, retry, or (if unlocked) the next level.

Progress is stored on the device (`shared_preferences`). Level ids are stable across languages (`addition-l1`, `subtraction-l1`, `counting-l1`, `vocab-l1`, …).

## Verify TTS in Chrome

Chrome Speech Synthesis quality depends on installed voices. CoolSchool asks for BCP-47 tags in this order and prefers a higher-quality match (Google / neural / enhanced) when the browser exposes it:

| Chip | Tried first | Then |
| --- | --- | --- |
| DE | `de-CH` | `de-DE`, `de-AT`, `de` |
| FR | `fr-CH` | `fr-FR`, `fr-CA`, `fr` |
| EN | `en-GB` | `en-US`, `en` |
| RO | `ro-RO` | `ro` |

Rate is slightly under the engine default so kids can follow. Math is spoken as words (`deux plus trois`), never digit soup (`2 + 3`). If a voice is missing, the next tag is tried.

On `https://michaelady.github.io/CoolSchool/` or `flutter run -d chrome`:

1. Open **DevTools → Console**.
2. List voices:

```js
speechSynthesis.getVoices().map(v => `${v.lang} — ${v.name}`).sort()
```

3. Confirm you have at least one `fr-*` voice (Chrome usually ships **Google français** / `fr-FR`). Without any French voice, the browser may fall back to a German or English voice — that is the “strange French” problem this path avoids when a FR voice exists.
4. Home → **FR** → Addition → first level. Tap **Lire**. You should hear *« Combien font un plus un ? »*, not *« 1 + 1 »*.
5. Repeat with **DE** (*« Was ist eins plus eins? »*), **EN** (*« What is one plus one? »*), **RO** (*« Cât fac unu plus doi? »* on later items).
6. Optional: in DevTools, `speechSynthesis.speaking` is `true` while a prompt plays. Mute still silences TTS and SFX for the rest of the session.

## Content and architecture

JSON packs live under `assets/content/packs/` and stay separate from UI:

| Topic | Files | LP21 |
| --- | --- | --- |
| Addition | `addition_{de,fr,en,ro}.json` | MA.1 Operieren |
| Subtraction | `subtraction_{de,fr,en,ro}.json` | MA.1 Operieren |
| Counting | `counting_{de,fr,en,ro}.json` | MA.1 Anzahlen |
| Schulsprache | `vocab_{de,fr,en,ro}.json` | D.1 / L1.1 Wortschatz |

```
lib/
  content/     models + JSON loader
  game/        scoring, level unlock, local progress
  audio/       TTS (BCP-47 + spoken math) + SFX
  l10n/        DE / FR / EN / RO strings
  ui/          home → topic → exercise → reward
```

SFX in `assets/sounds/` are short original WAVs (`python3 tool/generate_sfx.py`): `correct`, `wrong`, `levelup`, `transition`, `next`. Display font is [Fredoka](https://fonts.google.com/specimen/Fredoka) (SIL OFL, `assets/fonts/OFL.txt`).

Regenerate packs (except the original hand-tuned DE/FR addition files) with `python3 tool/generate_packs.py`.

## Tests

```bash
flutter test
flutter analyze --no-fatal-infos
```

CI (`/.github/workflows/web.yml`) runs analyze + test on every PR, then deploys `main` to Pages.

- Unit: star scoring, level unlock, spoken math, voice picker, pack catalog
- Widget: language chips, four topics, feedback hold, sticky mute, reward Home

The visible Richtig/Schade hold from **PR #3** is merged on `main` and included here.
