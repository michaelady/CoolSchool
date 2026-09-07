# CoolSchool

Kid-safe practice game for Swiss **Lehrplan 21**, Zyklus 1–2 (ages ≤ 10). Phase 1 is a playable **Flutter web** app: Addition with three short levels, German TTS by default, a French pack, stars, and local progress only.

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
flutter run -d chrome
```

Web release build (same flags as CI):

```bash
flutter build web --release --base-href /CoolSchool/
```

Serve the output with any static server, for example:

```bash
python3 -m http.server 8080 --directory build/web
```

Android stays scaffolded for a later APK (`flutter build apk`). Not part of Phase 1.

## How to play

1. Home → **Addition** (large topic card).
2. Pick a level. Level 1 is open; later levels unlock after at least one star on the previous level.
3. Each prompt is read aloud (Chrome Speech Synthesis, `de-DE` or `fr-FR`). Tap **Vorlesen** / **Lire** to hear it again.
4. Tap an answer. Correct / wrong SFX play unless mute is on. Mute lasts for the session.
5. Finish the short set to earn 1–3 stars, then go **Home**, retry, or (if unlocked) the next level.

Language chips **DE / FR** on Home switch the content pack. Progress is stored on the device (`shared_preferences`) and is shared across languages because level ids are stable (`addition-l1` …).

## Content and architecture

JSON packs live under `assets/content/packs/` and stay separate from UI:

| File | Locale | Topic |
| --- | --- | --- |
| `addition_de.json` | German (default) | Addition, 3 levels |
| `addition_fr.json` | French | Same exercises, FR strings |

Each pack carries lightweight LP21 tags, for example `MA.1 Zahl und Variable` and `MA.1.B Operieren und benennen`.

```
lib/
  content/     models + JSON loader
  game/        scoring, level unlock, local progress
  audio/       TTS + SFX (injectable no-ops for tests)
  ui/          home → topic → exercise → reward
```

SFX in `assets/sounds/` are short original WAVs (`python3 tool/generate_sfx.py`). Display font is [Fredoka](https://fonts.google.com/specimen/Fredoka) (SIL OFL, `assets/fonts/OFL.txt`).

## Tests

```bash
flutter test
```

- Unit: star scoring and level unlock
- Widget: home smoke, navigation with no dead end, one complete mini-run that writes stars
