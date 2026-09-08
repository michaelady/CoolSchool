# CoolSchool

Kid-safe practice game for the Swiss **Plan d’études romand (PER)**, cycles **1H–8H / 1–2** (ages ≤ 10). Flutter **web** first: six domains, twenty difficulties each, four languages, local stars only.

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

Regenerate all domain packs (6 × 20 × DE/FR/EN/RO) with:

```bash
python3 tool/generate_packs.py
```

Android stays scaffolded for a later APK (`flutter build apk`).

## How to play

1. Home language chips: **DE / FR / EN / RO** (always visible above the sun).
2. Pick a **domain** card (all six PER areas).
3. Pick a difficulty **1–20**. Level 1 is open; later levels unlock after at least one star on the previous level.
4. Each prompt is read aloud. Tap **Vorlesen** / **Lire** / **Read aloud** / **Citește** to hear it again.
5. **Tap** a choice **or type** a short answer (numbers, spellings). Typed answers are trimmed, case-insensitive, and accent-tolerant for French/Romanian when that is fair (`ecole` = `école`, `scoala` = `școală`).
6. The localized banner (**Richtig!** / **Bravo !** / **Right!** / **Corect!**, or **Schade!** / **Presque !** / **Almost!** / **Aproape!**) stays about 1.6s. Correct / wrong SFX play unless mute is on.
7. A short **transition** whoosh plays between screens. A soft **next** pop plays after the hold when the next prompt appears. Level-complete uses the rising fanfare. Mute is sticky for the session.
8. Finish the short set to earn 1–3 stars, then **Home**, retry, or (if unlocked) the next level.

Progress is stored on the device (`shared_preferences`). Level ids are stable across languages (`langues-l1`, `math_sciences-l7`, …).

Phase 1–2 addition, subtraction, counting, and school-language vocab now live inside **Mathématiques et sciences de la nature** and **Langues**.

## PER mapping

Packs tag each domain and each difficulty with PER-ish competence ids (`per` / `perTag` in JSON). These are teaching-friendly labels, not a legal extract of the official PER.

| Home domain | Pack id | PER-ish codes | What kids practice (1H–8H) |
| --- | --- | --- | --- |
| Langues | `langues` | **L1 11** oral/vocab, **L1 21** write; later **L2 11** (DE) and **L3 11** (EN) | School-language words, listen, type/spell; simple German then English as L2/L3 (or FR when the UI is already DE/EN) |
| Mathématiques et sciences de la nature | `math_sciences` | **MSN 16** numbers, **MSN 17** operations, **MSN 18** measures, **MSN 21** space, **MSN 22** living world | Counting, +/− (spoken as words), type the number; living/not, seasons, senses, water, shapes |
| Sciences humaines et sociales | `shs` | **SHS 11** space, **SHS 21** time, **SHS 31** living together | Family, school, weather, map symbols, Switzerland, then/now, jobs, sharing, care for nature |
| Arts | `arts` | **A 11 AV** visual, **A 13 MU** music, **A 12 AM** making | Colors, mix, shapes, loud/soft, instruments, patterns, rhythm, decorate |
| Corps et mouvement | `corps` | **CM 11** moving, **CM 16** health, **CM 12** safety / fair play | Body parts, left/right, sport, food/water/sleep, wash, helmet, team, rest |
| Éducation numérique | `numerique` | **EN 11** use & safety, **EN 21** / **MITIC** sequences | Devices, click/type, password as secret, ask an adult, kind messages, first/then, robot left/right |

Difficulty **1** is easiest (cycle 1 / early 1H–4H). **20** is still age ≤ 10 (cycle 2 / 7H–8H): two-digit numbers, short spellings, simple civic and digital-safety ideas. No secondary-school content.

Former Lehrplan 21 labels (MA.1, D.1, …) are replaced by these PER ids. The JSON field is `per`; loaders still accept a legacy `lp21` block.

## Verify TTS locales on web

Chrome Speech Synthesis quality depends on **installed language voices**. CoolSchool never leaves DE/FR/RO prompts on the browser default English voice on purpose:

1. `flutter_tts.setLanguage` is always called with a real BCP-47 tag **before** (and again after) `setVoice`.
2. Installed voices are scored; an English voice is **never** selected for DE, FR, or RO.
3. Math is rewritten by `SpokenMath` into words (`deux plus trois`, `cinci scăzut doi`), never digit soup (`2 + 3`).
4. Rate stays slightly under the engine default (`0.46`) so kids can follow.
5. If the browser lists voices and none match, a small **non-blocking hint** appears on the exercise screen (dismiss with ×). An empty voice list (Chrome before `voiceschanged`) does **not** show that hint.

| Chip | Tried first | Then |
| --- | --- | --- |
| DE | `de-CH` | `de-DE`, `de-AT`, `de` |
| FR | `fr-CH` | `fr-FR`, `fr-CA`, `fr` |
| EN | `en-GB` | `en-US`, `en` |
| RO | `ro-RO` | `ro` |

On `https://michaelady.github.io/CoolSchool/` or `flutter run -d chrome`:

1. Open **DevTools → Console**.
2. List voices:

```js
speechSynthesis.getVoices().map(v => `${v.lang} — ${v.name}`).sort()
```

3. Confirm you have at least one `fr-*` voice (Chrome usually ships **Google français** / `fr-FR`). Without any French voice, the engine may still fall back to English — that is exactly when the in-app hint should appear. Installing a French voice (Chrome language settings / OS speech pack) fixes pronunciation.
4. Home → **FR** → **Maths et nature** → level 1. Tap **Lire**. You should hear *« Combien font un plus un ? »*, not *« 1 + 1 »* and not English phonemes for French words.
5. Repeat with **DE** (*« Was ist eins plus eins? »*), **EN** (*« What is one plus one? »*), **RO** (*« Cât fac cinci scăzut doi? »* on later minus items).
6. Optional: `speechSynthesis.speaking` is `true` while a prompt plays. Mute still silences TTS and SFX for the rest of the session.

To confirm the utterance language in DevTools while a prompt plays, Chrome’s SpeechSynthesis does not always log `lang`; the reliable check is a matching `fr-*` / `de-*` / `ro-*` voice in `getVoices()` plus the spoken result.

## Content and architecture

JSON packs live under `assets/content/packs/{domain}_{de,fr,en,ro}.json` and stay separate from UI.

```
lib/
  content/     models + typing check + JSON loader
  game/        scoring, level unlock, local progress
  audio/       TTS (BCP-47 + spoken math) + SFX
  l10n/        DE / FR / EN / RO strings
  ui/          home → domain → 1–20 picker → exercise → reward
```

SFX in `assets/sounds/` are short original WAVs (`python3 tool/generate_sfx.py`): `correct`, `wrong`, `levelup`, `transition`, `next`. Display font is [Fredoka](https://fonts.google.com/specimen/Fredoka) (SIL OFL, `assets/fonts/OFL.txt`).

## Tests

```bash
flutter test
flutter analyze --no-fatal-infos
```

CI (`/.github/workflows/web.yml`) runs analyze + test on every PR, then deploys `main` to Pages.

- Unit: star scoring, level unlock, spoken math, TTS locale picker (never English for DE/FR/RO), typing validation, pack catalog (6 × 20)
- Widget: language chips above the sun, six domain cards, feedback hold, typed answers, sticky mute, reward Home
