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
3. Pick a difficulty **1–20**. **Levels 1–5 are always open** so kids can explore. After that, finishing a level (any score, even 0 stars) unlocks the next one. Stars stay a 1–3 badge; they do not gate access.
4. Each prompt is read aloud. Tap **Vorlesen** / **Lire** / **Read aloud** / **Citește** to hear it again.
5. **Tap** a choice **or type** a short answer (numbers, spellings). Every domain has a typed exercise in **level 1** (Langues/Math: second item, right after the opener). Typed answers are trimmed, case-insensitive, and accent-tolerant for French/Romanian when that is fair (`ecole` = `école`, `scoala` = `școală`).
6. The localized banner (**Richtig!** / **Bravo !** / **Right!** / **Corect!**, or **Schade!** / **Presque !** / **Almost!** / **Aproape!**) stays about 1.6s. Correct / wrong SFX play unless mute is on.
7. A short **transition** whoosh plays between screens. A soft **next** pop plays after the hold when the next prompt appears. Level-complete uses the rising fanfare. Mute is sticky for the session.
8. Finish the short set to earn 1–3 stars, then **Home**, retry, or (if unlocked) the next level.

Progress is stored on the device (`shared_preferences`). Level ids are stable across languages (`langues-l1`, `math_sciences-l7`, …).

### Level unlock (kid-friendly)

Stars are a quality badge, not a gate. The playable rule lives in `LevelUnlock` (`lib/game/scoring.dart`):

| Band | Rule |
| --- | --- |
| **1–5** | Always unlocked on every domain (first cycle-1 band, for exploration and QA). |
| **6–20** | Unlocks when the **previous** level has been finished at least once, **including 0 stars**. |

JSON `unlockAfterStars` is catalog metadata only. Completing level 5 (any score) opens 6, completing 6 opens 7, and so on. Older installs that only stored stars still count a starred level as finished.

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

## Pronunciation packs (DE / FR / EN / RO)

BCP-47 on `flutter_tts` / Web Speech is **not enough** when Chrome only has English voices — the engine then reads French or German with English phonemes. CoolSchool therefore ships a **dedicated language package** for each UI chip:

| Chip | Pack id | Voice file | Phoneme language |
| --- | --- | --- | --- |
| DE | `coolschool-de` | `web/tts/voices/de.json` | German (`de`, tag `de-CH`) |
| FR | `coolschool-fr` | `web/tts/voices/fr.json` | French (`fr`, tag `fr-CH`) |
| EN | `coolschool-en` | `web/tts/voices/en/en.json` | English (`en/en`, tag `en-GB`) |
| RO | `coolschool-ro` | `web/tts/voices/ro.json` | Romanian (`ro`, tag `ro-RO`) |

The synthesizer is **meSpeak / eSpeak** (`web/tts/mespeak.js` + `mespeak-core.js`, GPL-3 — see `web/tts/NOTICE`). Each JSON pack is that language’s dictionary and voice, not an English voice with a `lang` attribute.

Selection (`TtsPackPicker` in `lib/audio/tts_packs.dart`):

1. **Default:** speak with the shipped pack for the active chip (`coolschool-de` / `fr` / `en` / `ro`) through `#coolschool-tts` (same HTML audio unlock as the whoosh). No query flag is required.
2. Always bind the utterance to that pack. **DE / FR / RO never receive the English pack** and never receive an `en-*` system voice.
3. Optional opt-in: `?tts=system` uses a **matching** native browser/OS voice when one exists (e.g. Google français). If none matches, the shipped pack is still used.
4. Math is still rewritten by `SpokenMath` (`deux plus trois`, `cinci scăzut doi`), never digit soup (`2 + 3`).
5. Android keeps the same pack ids and picker. The JS engine is web-only, so Android uses `flutter_tts` when a system language pack is installed; otherwise the in-app hint still appears. A future native eSpeak plugin can load the same voice files.

A missing-voice hint is shown only when voices were enumerated, none match, **and** no bundled pack engine is available. On Flutter web the four packs are always available, so English-only Chrome no longer shows that hint for FR/DE/RO.

Playback (`web/tts/coolschool_tts.js`) keeps those packs as the default and smooths DE/FR/RO (English ASCII was already fine):

- eSpeak reads **UTF-8** (`utf16: true` → `-b 4`). The engine default is 8-bit, which garbles `é` / `ä` / `â` into clicks.
- One WAV per prompt (not per word). A generation token drops stale worker callbacks so a second **Lire** / **Vorlesen** cannot overlap the first.
- No Klatt `f2` echo/breath variant, `wordgap` 0, amplitude 88 (not clipped at 100).
- Short cosine fade in/out on the PCM, Blob URL into `#coolschool-tts`, and a volume fade on stop. Do **not** `pause` + clear `src` + `load()` (that pop).
- First-pointer unlock plays the audio tags **muted** so the empty TTS element does not click.

### How to verify on web

On `https://michaelady.github.io/CoolSchool/` or `flutter run -d chrome` (no query flag — shipped packs are the default):

1. Open **DevTools → Console**.
2. Optional — list browser voices (they may be English-only; that is the case this feature is for):

```js
speechSynthesis.getVoices().map(v => `${v.lang} — ${v.name}`).sort()
```

3. Home → **FR** → **Maths et nature** → level 1. Tap **Lire**.
4. You should hear French phonemes (*« Combien font un plus un ? »*) **without** clicks, pops, or the voice cutting out mid-sentence. In the console:

```js
CoolSchoolTts.lastUtterance
// { locale: "fr", packId: "coolschool-fr", voiceId: "fr", engine: "bundled-espeak", encoding: "utf-8", wordgap: 0, … }
CoolSchoolTts.speakSettings('fr').utf16  // true → UTF-8
```

5. Home → **EN** → same level → **Read aloud**. `lastUtterance.packId` must be `coolschool-en`. FR must **not** have used `en/en`.
6. Repeat **DE** → **Vorlesen** (*« Was ist eins plus eins? »* / `coolschool-de`, try *Äpfel*) and **RO** (*« Cât fac unu plus unu? »* / `coolschool-ro`). Accents must stay smooth.
7. Mute still silences TTS and SFX for the rest of the session. Chips, feedback hold, whoosh, domains, and typing are unchanged.

To try a matching Chrome/OS voice instead, append `?tts=system`. If `CoolSchoolTts.lastUtterance` is then `null`, SpeechSynthesis handled that utterance. Remove the flag (or open the site with no query) to hear the dedicated packs again.

## Content and architecture

JSON packs live under `assets/content/packs/{domain}_{de,fr,en,ro}.json` and stay separate from UI.

```
lib/
  content/     models + typing check + JSON loader
  game/        scoring, level unlock, local progress
  audio/       TTS language packs (eSpeak per locale) + spoken math + SFX
  web/tts/     meSpeak engine + de/fr/en/ro voice JSON
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

- Unit: star scoring, kid-friendly unlock (L1–5 free, then finish-previous), spoken math, TTS locale→pack picker (never an English voice/pack for DE/FR/RO when a native pack exists), typing validation, pack catalog (6 × 20, type in every L1)
- Widget: language chips above the sun, six domain cards, L1–5 open, Langues/Math L1 TextField e2e, feedback hold, sticky mute, reward Home
