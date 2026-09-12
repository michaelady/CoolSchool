#!/usr/bin/env python3
"""Generate CoolSchool Phase 3 packs: 6 PER domains × 20 levels × DE/FR/EN/RO."""

from __future__ import annotations

import json
import re
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "content" / "packs"

DOMAINS = ["langues", "math_sciences", "shs", "arts", "corps", "numerique"]
LANGS = ("de", "fr", "en", "ro")

OLD_TOPICS = ("addition", "subtraction", "counting", "vocab")


def dump(name: str, data: dict) -> None:
    path = OUT / name
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(path)


def t(lang: str, de: str, fr: str, en: str, ro: str) -> str:
    return {"de": de, "fr": fr, "en": en, "ro": ro}[lang]


def ex(
    eid: str,
    prompt: str,
    tts: str,
    choices: list | None = None,
    correct: int = 0,
    **extra,
) -> dict:
    row = {
        "id": eid,
        "prompt": prompt,
        "promptTts": tts,
    }
    if extra.get("answerMode") == "type":
        row["answerMode"] = "type"
        row["acceptedAnswers"] = [str(a) for a in extra.pop("acceptedAnswers")]
        row["keyboard"] = extra.pop("keyboard", "text")
    else:
        assert choices is not None
        row["choices"] = [str(c) for c in choices]
        row["correctIndex"] = correct
    row.update(extra)
    return row


def typed(eid: str, prompt: str, tts: str, answers: list, keyboard: str = "text", **extra) -> dict:
    return ex(
        eid,
        prompt,
        tts,
        answerMode="type",
        acceptedAnswers=answers,
        keyboard=keyboard,
        **extra,
    )


def lvl(lid: str, title: str, subtitle: str, tag: str, unlock: int, items: list[dict]) -> dict:
    return {
        "id": lid,
        "title": title,
        "subtitle": subtitle,
        "perTag": tag,
        "unlockAfterStars": unlock,
        "exercises": items,
    }


# --- number words 0–100 (spoken math, never digit soup) ---

_BASE = {
    "de": {
        0: "null", 1: "eins", 2: "zwei", 3: "drei", 4: "vier", 5: "fünf", 6: "sechs",
        7: "sieben", 8: "acht", 9: "neun", 10: "zehn", 11: "elf", 12: "zwölf",
        13: "dreizehn", 14: "vierzehn", 15: "fünfzehn", 16: "sechzehn", 17: "siebzehn",
        18: "achtzehn", 19: "neunzehn", 20: "zwanzig",
    },
    "fr": {
        0: "zéro", 1: "un", 2: "deux", 3: "trois", 4: "quatre", 5: "cinq", 6: "six",
        7: "sept", 8: "huit", 9: "neuf", 10: "dix", 11: "onze", 12: "douze",
        13: "treize", 14: "quatorze", 15: "quinze", 16: "seize", 17: "dix-sept",
        18: "dix-huit", 19: "dix-neuf", 20: "vingt",
    },
    "en": {
        0: "zero", 1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six",
        7: "seven", 8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve",
        13: "thirteen", 14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen",
        18: "eighteen", 19: "nineteen", 20: "twenty",
    },
    "ro": {
        0: "zero", 1: "unu", 2: "doi", 3: "trei", 4: "patru", 5: "cinci", 6: "șase",
        7: "șapte", 8: "opt", 9: "nouă", 10: "zece", 11: "unsprezece", 12: "doisprezece",
        13: "treisprezece", 14: "paisprezece", 15: "cincisprezece", 16: "șaisprezece",
        17: "șaptesprezece", 18: "optsprezece", 19: "nouăsprezece", 20: "douăzeci",
    },
}


def nword(lang: str, n: int) -> str:
    if n in _BASE[lang]:
        return _BASE[lang][n]
    if n == 100:
        return {"de": "hundert", "fr": "cent", "en": "one hundred", "ro": "o sută"}[lang]
    t, u = divmod(n, 10)
    if lang == "de":
        tens = {2: "zwanzig", 3: "dreißig", 4: "vierzig", 5: "fünfzig", 6: "sechzig",
                7: "siebzig", 8: "achtzig", 9: "neunzig"}
        if u == 0:
            return tens[t]
        unit = "ein" if u == 1 else _BASE["de"][u]
        return f"{unit}und{tens[t]}"
    if lang == "fr":
        if n < 70:
            tens = {2: "vingt", 3: "trente", 4: "quarante", 5: "cinquante", 6: "soixante"}
            if u == 0:
                return tens[t]
            if u == 1:
                return f"{tens[t]}-et-un"
            return f"{tens[t]}-{_BASE['fr'][u]}"
        if n < 80:
            return "soixante-et-onze" if n == 71 else f"soixante-{_BASE['fr'][n - 60]}"
        if n == 80:
            return "quatre-vingts"
        return f"quatre-vingt-{_BASE['fr'][n - 80]}"
    if lang == "en":
        tens = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty", 6: "sixty",
                7: "seventy", 8: "eighty", 9: "ninety"}
        if u == 0:
            return tens[t]
        return f"{tens[t]}-{_BASE['en'][u]}"
    tens = {2: "douăzeci", 3: "treizeci", 4: "patruzeci", 5: "cincizeci",
            6: "șaizeci", 7: "șaptezeci", 8: "optzeci", 9: "nouăzeci"}
    if u == 0:
        return tens[t]
    return f"{tens[t]} și {_BASE['ro'][u]}"


def add_tts(lang: str, a: int, b: int) -> str:
    left, right = nword(lang, a), nword(lang, b)
    return {
        "de": f"Was ist {left} plus {right}? Wähle die richtige Zahl.",
        "fr": f"Combien font {left} plus {right} ? Choisis le bon nombre.",
        "en": f"What is {left} plus {right}? Choose the right number.",
        "ro": f"Cât fac {left} plus {right}? Alege numărul potrivit.",
    }[lang]


def sub_tts(lang: str, a: int, b: int) -> str:
    left, right = nword(lang, a), nword(lang, b)
    minus = {"de": "minus", "fr": "moins", "en": "minus", "ro": "scăzut"}[lang]
    return {
        "de": f"Was ist {left} {minus} {right}? Wähle die richtige Zahl.",
        "fr": f"Combien font {left} {minus} {right} ? Choisis le bon nombre.",
        "en": f"What is {left} {minus} {right}? Choose the right number.",
        "ro": f"Cât fac {left} {minus} {right}? Alege numărul potrivit.",
    }[lang]


def nearby(n: int) -> tuple[list[str], int]:
    opts = [n - 1, n, n + 1]
    if n - 1 < 0:
        opts = [n, n + 1, n + 2]
    return [str(x) for x in opts], opts.index(n)


def how_many(lang: str) -> str:
    return t(lang, "Wie viele?", "Combien ?", "How many?", "Câte sunt?")


def count_tts(lang: str, noun: str) -> str:
    if lang == "fr":
        de = "d'" if noun[:1].lower() in "aeiouéèêëàâäîïôöùûüh" else "de "
        return f"Combien {de}{noun} vois-tu ? Compte-les bien."
    return {
        "de": f"Wie viele {noun} siehst du? Zähle sie in Ruhe.",
        "en": f"How many {noun} do you see? Count them carefully.",
        "ro": f"Câte {noun} vezi? Numără-le cu grijă.",
    }[lang]


def write_word(lang: str, word: str) -> tuple[str, str]:
    prompt = t(lang, f"Schreib: {word}", f"Écris : {word}", f"Type: {word}", f"Scrie: {word}")
    tts = t(
        lang,
        f"Schreib bitte das Wort {word}.",
        f"Écris le mot {word}, s’il te plaît.",
        f"Please type the word {word}.",
        f"Te rog, scrie cuvântul {word}.",
    )
    return prompt, tts


def type_number_tts(lang: str, number_words: str | None = None) -> str:
    extra = " ".join(str(number_words or "").split()).strip().rstrip(".!?")
    if extra:
        return t(
            lang,
            f"Schreib bitte die Zahl {extra}.",
            f"Écris le nombre {extra}, s’il te plaît.",
            f"Please type the number {extra}.",
            f"Te rog, scrie numărul {extra}.",
        )
    return t(
        lang,
        "Schreib bitte die Zahl.",
        "Écris le nombre, s’il te plaît.",
        "Please type the number.",
        "Te rog, scrie numărul.",
    )


def type_number_prompt(lang: str) -> tuple[str, str]:
    return (
        t(lang, "Schreib die Zahl", "Écris le nombre", "Type the number", "Scrie numărul"),
        type_number_tts(lang),
    )


def listen_word(lang: str, word: str) -> str:
    spoken = strip_spoken_symbols(replace_arrows(lang, word)).rstrip(".!?").strip()
    if not spoken:
        return pattern_tts(lang)
    if _TYPE_HEAD.match(spoken):
        return polish_type_line(lang, spoken, spoken)
    return t(
        lang,
        f"Hör gut zu, das Wort ist {spoken}.",
        f"Écoute bien ce mot : {spoken}.",
        f"Listen carefully to this word: {spoken}.",
        f"Ascultă bine acest cuvânt: {spoken}.",
    )


def spoken_word_count(text: str) -> int:
    return len([w for w in re.findall(r"[^\W_]+", text, flags=re.UNICODE) if w])


YES_NO = {
    "ja", "nein", "oui", "non", "yes", "no", "da", "nu",
}

# Pictographs / dingbats / arrows that eSpeak would try to name.
_SYMBOL_RE = re.compile(
    "["
    "\U0001F000-\U0001FFFF"
    "\U00002700-\U000027BF"
    "\U00002600-\U000026FF"
    "\U00002B00-\U00002BFF"
    "\U000025A0-\U000025FF"
    "\U00002300-\U000023FF"
    "\U00002190-\U000021FF"
    "\U0000266A-\U0000266F"
    "\U0000FE00-\U0000FE0F"
    "\U0000200D"
    "]+",
)

_TYPE_HEAD = re.compile(r"^(schreib(?:e)?|écris|ecris|type|scrie)\b", re.I)
_NUMBER_HINT = re.compile(r"\b(zahl|nombre|number|num[aă]rul)\b", re.I)
_TYPE_TARGET = re.compile(
    r"^(?P<verb>schreib(?:e)?|écris|ecris|type|scrie)\b"
    r"(?:\s+(?:bitte|please|te rog))?"
    r"(?:\s+(?:das wort|le mot|the word|cuv[aâ]ntul|die zahl|le nombre|the number|num[aă]rul))?"
    r"(?:\s*[:：])?"
    r"\s*(?P<rest>.*?)$",
    re.I | re.S,
)
_POLITE_ONLY = re.compile(
    r"^(?:,?\s*)?(?:s[’']il te pla[îi]t|please|bitte|te rog)\.?$",
    re.I,
)
_LISTEN_HEAD = ("hör", "écoute", "listen", "ascult")
_ARROW_WORDS = {
    "⬅\ufe0f": {"de": "links", "fr": "à gauche", "en": "left", "ro": "la stânga"},
    "➡\ufe0f": {"de": "rechts", "fr": "à droite", "en": "right", "ro": "la dreapta"},
    "⬅": {"de": "links", "fr": "à gauche", "en": "left", "ro": "la stânga"},
    "➡": {"de": "rechts", "fr": "à droite", "en": "right", "ro": "la dreapta"},
}


def replace_arrows(lang: str, text: str) -> str:
    out = str(text)
    for glyph, words in _ARROW_WORDS.items():
        out = out.replace(glyph, f" {words[lang]} ")
    return out


def strip_spoken_symbols(text: str) -> str:
    cleaned = _SYMBOL_RE.sub(" ", str(text))
    cleaned = re.sub(r"\s+", " ", cleaned)
    cleaned = re.sub(r"([?!.])(?:\s*[?!.])+", r"\1", cleaned)
    cleaned = re.sub(r"\s+([,.;:])", r"\1", cleaned)
    cleaned = re.sub(r"\s*[:;,\-—/]+\s*$", "", cleaned)
    return cleaned.strip(" \t-—:")


def pattern_tts(lang: str) -> str:
    return t(
        lang,
        "Was kommt als Nächstes im Muster? Wähle das richtige Bild.",
        "Qu’est-ce qui vient ensuite dans le motif ? Choisis la bonne image.",
        "What comes next in the pattern? Choose the right picture.",
        "Ce urmează în model? Alege imaginea potrivită.",
    )


def expand_quiz_question(lang: str, question: str) -> str:
    q = strip_spoken_symbols(replace_arrows(lang, question)).rstrip(".!").strip()
    if not q:
        return pattern_tts(lang)
    if not q.endswith("?"):
        q = f"{q} ?" if lang == "fr" else f"{q}?"
    return t(
        lang,
        f"{q} Wähle die richtige Antwort.",
        f"{q} Choisis la bonne réponse.",
        f"{q} Choose the right answer.",
        f"{q} Alege răspunsul potrivit.",
    )


def _type_rest(text: str) -> str:
    match = _TYPE_TARGET.match(text.strip())
    if not match:
        return ""
    rest = " ".join(match.group("rest").split()).strip().rstrip(".!?")
    if not rest or _POLITE_ONLY.match(rest):
        return ""
    rest = re.sub(
        r"(?:,?\s*)(?:s[’']il te pla[îi]t|please|bitte|te rog)\.?$",
        "",
        rest,
        flags=re.I,
    ).strip(" ,")
    return rest


def polish_type_line(lang: str, prompt: str, tts: str) -> str:
    source = tts or prompt
    rest = _type_rest(source) or _type_rest(prompt)
    numberish = bool(_NUMBER_HINT.search(source) or _NUMBER_HINT.search(prompt) or re.search(r"\d", prompt))
    if numberish:
        return type_number_tts(lang, rest or None)
    if rest:
        return write_word(lang, rest)[1]
    return write_word(lang, source.split()[-1])[1] if source.split() else type_number_tts(lang)


def looks_like_visual_pattern(prompt: str, tts: str) -> bool:
    if spoken_word_count(strip_spoken_symbols(tts)) == 0 and _SYMBOL_RE.search(str(tts)):
        return True
    if spoken_word_count(strip_spoken_symbols(tts)) == 0 and _SYMBOL_RE.search(str(prompt)):
        return True
    return False


def has_spoken_symbols(text: str) -> bool:
    return bool(_SYMBOL_RE.search(str(text)))


def has_type_listen_wrap(text: str) -> bool:
    return bool(
        re.search(
            r"(écoute bien ce mot|hör gut zu, das wort ist|"
            r"ascultă bine acest cuvânt|listen carefully to this word)"
            r".{0,8}(schreib|écris|ecris|type|scrie)",
            str(text),
            flags=re.I,
        )
    )


def has_english_leakage(lang: str, text: str) -> bool:
    if lang == "en":
        return False
    low = str(text).lower()
    return (
        "listen to this word" in low
        or "listen carefully" in low
        or "type the number" in low
        or "type the word" in low
    )


def enrich_spoken(lang: str, prompt: str, tts: str) -> str:
    """Turn short Lire/Vorlesen cues into a kid sentence, without emoji or type-wraps."""
    raw_tts = " ".join(str(tts).split()).strip()
    raw_prompt = " ".join(str(prompt).split()).strip()
    if looks_like_visual_pattern(raw_prompt, raw_tts):
        return pattern_tts(lang)

    cleaned = strip_spoken_symbols(replace_arrows(lang, raw_tts)).strip()
    prompt_s = strip_spoken_symbols(replace_arrows(lang, raw_prompt)).strip()
    if not cleaned:
        cleaned = prompt_s
    if not cleaned:
        return pattern_tts(lang)

    if _TYPE_HEAD.match(cleaned) or _TYPE_HEAD.match(prompt_s):
        if spoken_word_count(cleaned) >= 4 and _TYPE_HEAD.match(cleaned) and (
            "bitte" in cleaned.lower()
            or "please" in cleaned.lower()
            or "plaît" in cleaned.lower()
            or "plait" in cleaned.lower()
            or "te rog" in cleaned.lower()
        ):
            return cleaned
        return polish_type_line(lang, prompt_s, cleaned)

    if spoken_word_count(cleaned) >= 4:
        return cleaned

    bare = cleaned.rstrip(".!?").strip().lower()
    if bare in YES_NO:
        return t(
            lang,
            f"{prompt_s} Tippe ja oder nein.",
            f"{prompt_s} Touche oui ou non.",
            f"{prompt_s} Tap yes or no.",
            f"{prompt_s} Atinge da sau nu.",
        )

    word = cleaned.rstrip(".!?")
    prompt_bare = prompt_s.rstrip(".!?").strip().lower()
    word_bare = word.strip().lower()
    listen_prompt = any(prompt_s.lower().startswith(h) for h in _LISTEN_HEAD)
    if listen_prompt:
        return listen_word(lang, word)
    if prompt_bare == word_bare:
        if "?" in prompt_s or "?" in cleaned:
            return expand_quiz_question(lang, prompt_s or cleaned)
        return listen_word(lang, word)

    if prompt_s and spoken_word_count(cleaned) <= 4:
        if re.search(r"\d\s*[+\-−]", prompt_s):
            return expand_quiz_question(lang, prompt_s)
        if "?" in prompt_s:
            return t(
                lang,
                f"{prompt_s} Hör zu: {word}.",
                f"{prompt_s} Écoute : {word}.",
                f"{prompt_s} Listen: {word}.",
                f"{prompt_s} Ascultă: {word}.",
            )
        if prompt_s.endswith(("…", "...")):
            return t(
                lang,
                f"{prompt_s} Hör zu, das Wort ist {word}.",
                f"{prompt_s} Écoute, le mot est {word}.",
                f"{prompt_s} Listen, the word is {word}.",
                f"{prompt_s} Ascultă, cuvântul este {word}.",
            )
        return t(
            lang,
            f"{prompt_s}. Hör zu, das Wort ist {word}.",
            f"{prompt_s}. Écoute, le mot est {word}.",
            f"{prompt_s}. Listen, the word is {word}.",
            f"{prompt_s}. Ascultă, cuvântul este {word}.",
        )
    if spoken_word_count(cleaned) < 4:
        if "?" in cleaned:
            return expand_quiz_question(lang, cleaned)
        return listen_word(lang, cleaned.rstrip(".!?"))
    return cleaned


# ---------------------------------------------------------------------------
# Domain metadata
# ---------------------------------------------------------------------------

META = {
    "langues": {
        "emoji": "🗣️",
        "color": "#4CC9F0",
        "title": lambda lang: t(lang, "Sprachen", "Langues", "Languages", "Limbi"),
        "subtitle": lambda lang: t(
            lang, "Wörter, Hören, Schreiben", "Mots, écouter, écrire",
            "Words, listen, write", "Cuvinte, ascult, scriu",
        ),
        "per": lambda lang: {
            "competenceId": "L1 11",
            "label": t(lang, "Schulsprache", "Langue de scolarisation", "School language", "Limba școlii"),
            "focusId": "L1 21",
            "focusLabel": t(lang, "Schreiben & Wortschatz", "Écrire et vocabulaire", "Writing & vocabulary", "Scriere și vocabular"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
    "math_sciences": {
        "emoji": "🔢",
        "color": "#FF8A5B",
        "title": lambda lang: t(lang, "Mathematik & Natur", "Maths et nature", "Maths & nature", "Mate și natură"),
        "subtitle": lambda lang: t(
            lang, "Rechnen und staunen", "Compter et découvrir",
            "Count and discover", "Numărăm și descoperim",
        ),
        "per": lambda lang: {
            "competenceId": "MSN 16",
            "label": t(lang, "Zahlen & Natur", "Nombres et nature", "Numbers & nature", "Numere și natură"),
            "focusId": "MSN 17",
            "focusLabel": t(lang, "Operieren", "Opérations", "Operations", "Operații"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
    "shs": {
        "emoji": "🌍",
        "color": "#A78BFA",
        "title": lambda lang: t(lang, "Mensch & Gesellschaft", "Sciences humaines", "Human & social", "Științe umane"),
        "subtitle": lambda lang: t(
            lang, "Ort, Zeit, zusammen leben", "Espace, temps, vivre ensemble",
            "Place, time, living together", "Loc, timp, împreună",
        ),
        "per": lambda lang: {
            "competenceId": "SHS 11",
            "label": t(lang, "Raum & Zeit", "Espace et temps", "Space & time", "Spațiu și timp"),
            "focusId": "SHS 31",
            "focusLabel": t(lang, "Zusammenleben", "Vivre ensemble", "Living together", "A trăi împreună"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
    "arts": {
        "emoji": "🎨",
        "color": "#F472B6",
        "title": lambda lang: t(lang, "Künste", "Arts", "Arts", "Arte"),
        "subtitle": lambda lang: t(
            lang, "Farben, Formen, Musik", "Couleurs, formes, musique",
            "Colors, shapes, music", "Culori, forme, muzică",
        ),
        "per": lambda lang: {
            "competenceId": "A 11 AV",
            "label": t(lang, "Bildnerisches Gestalten", "Arts visuels", "Visual arts", "Arte vizuale"),
            "focusId": "A 13 MU",
            "focusLabel": t(lang, "Musik", "Musique", "Music", "Muzică"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
    "corps": {
        "emoji": "⚽",
        "color": "#2FA84A",
        "title": lambda lang: t(lang, "Körper & Bewegung", "Corps et mouvement", "Body & movement", "Corp și mișcare"),
        "subtitle": lambda lang: t(
            lang, "Bewegen, Gesundheit, Fairplay", "Bouger, santé, fair-play",
            "Move, health, fair play", "Mișcare, sănătate, fair-play",
        ),
        "per": lambda lang: {
            "competenceId": "CM 11",
            "label": t(lang, "Bewegen", "Se mouvoir", "Moving", "Mișcare"),
            "focusId": "CM 16",
            "focusLabel": t(lang, "Gesundheit", "Santé", "Health", "Sănătate"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
    "numerique": {
        "emoji": "💻",
        "color": "#38BDF8",
        "title": lambda lang: t(lang, "Digitale Bildung", "Éducation numérique", "Digital education", "Educație digitală"),
        "subtitle": lambda lang: t(
            lang, "Geräte, Sicherheit, Sequenz", "Outils, sécurité, séquence",
            "Tools, safety, sequence", "Unelte, siguranță, secvență",
        ),
        "per": lambda lang: {
            "competenceId": "EN 11",
            "label": t(lang, "Nutzung", "Usages", "Use", "Utilizare"),
            "focusId": "EN 21",
            "focusLabel": t(lang, "Informatisches Denken", "Pensée informatique", "Computational thinking", "Gândire informatică"),
            "cycle": t(lang, "1H–8H · Zyklus 1–2", "1H–8H · cycles 1–2", "1H–8H · cycles 1–2", "1H–8H · ciclurile 1–2"),
        },
    },
}

LEVEL_TITLE = lambda lang, n: t(lang, f"Level {n}", f"Niveau {n}", f"Level {n}", f"Nivelul {n}")


def per_tag(domain: str, level: int) -> str:
    if domain == "langues":
        if level <= 6:
            return "L1 11 · oral / vocabulaire"
        if level <= 12:
            return "L1 21 · écrire"
        if level <= 16:
            return "L2 11 · allemand / L2"
        return "L3 11 · anglais / L3"
    if domain == "math_sciences":
        if level <= 3:
            return "MSN 16 · nombres"
        if level <= 12:
            return "MSN 17 · opérations"
        if level <= 17:
            return "MSN 22 · sciences de la nature"
        if level == 18:
            return "MSN 21 · espace"
        if level == 19:
            return "MSN 18 · mesures"
        return "MSN 16–23 · synthèse"
    if domain == "shs":
        if level <= 8:
            return "SHS 11 · espace"
        if level <= 14:
            return "SHS 21 · temps"
        return "SHS 31 · vivre ensemble"
    if domain == "arts":
        if level <= 8:
            return "A 11 AV · arts visuels"
        if level <= 14:
            return "A 13 MU · musique"
        return "A 12 AM · activités créatrices"
    if domain == "corps":
        if level <= 8:
            return "CM 11 · activités"
        if level <= 14:
            return "CM 16 · santé"
        return "CM 12 · sécurité / fair-play"
    if level <= 8:
        return "EN 11 · usages"
    if level <= 14:
        return "EN 11 · sécurité"
    return "EN 21 · MITIC / séquence"


SKILLS = {
    "langues": [
        ("Wörter und Bilder", "Mots et images", "Words and pictures", "Cuvinte și imagini"),
        ("Mehr Wörter", "Plus de mots", "More words", "Mai multe cuvinte"),
        ("Hör zu", "Écoute", "Listen", "Ascultă"),
        ("Erste Buchstaben", "Premières lettres", "First letters", "Primele litere"),
        ("Kurze Wörter tippen", "Mots courts", "Type short words", "Cuvinte scurte"),
        ("Schule schreiben", "Écrire l’école", "Spell school words", "Scriem școala"),
        ("Mit Akzent", "Avec accents", "With accents", "Cu accente"),
        ("Tiere", "Animaux", "Animals", "Animale"),
        ("Essen", "Nourriture", "Food", "Mâncare"),
        ("Längere Wörter", "Mots plus longs", "Longer words", "Cuvinte mai lungi"),
        ("Gegenteile", "Contraires", "Opposites", "Contrare"),
        ("Sätze hören", "Phrases", "Phrases", "Propoziții"),
        ("L2 Wörter 1", "Mots L2 1", "L2 words 1", "Cuvinte L2 1"),
        ("L2 Wörter 2", "Mots L2 2", "L2 words 2", "Cuvinte L2 2"),
        ("L2 tippen", "Taper L2", "Type L2", "Scriem L2"),
        ("L2 hören", "Écouter L2", "Hear L2", "Ascultăm L2"),
        ("L3 Wörter 1", "Mots L3 1", "L3 words 1", "Cuvinte L3 1"),
        ("L3 Wörter 2", "Mots L3 2", "L3 words 2", "Cuvinte L3 2"),
        ("L3 tippen", "Taper L3", "Type L3", "Scriem L3"),
        ("Sprachen-Mix", "Mélange", "Language mix", "Amestec"),
    ],
    "math_sciences": [
        ("Zahlenfreunde", "Amis des nombres", "Number friends", "Prietenii numerelor"),
        ("Kleine Mengen", "Petites quantités", "Small groups", "Grupuri mici"),
        ("Zähle bis 10", "Compter jusqu’à 10", "Count to 10", "Numără până la 10"),
        ("Plus bis 5", "Plus jusqu’à 5", "Plus to 5", "Plus până la 5"),
        ("Plus bis 10", "Plus jusqu’à 10", "Plus to 10", "Plus până la 10"),
        ("Minus bis 10", "Moins jusqu’à 10", "Minus to 10", "Minus până la 10"),
        ("Plus bis 20", "Plus jusqu’à 20", "Plus to 20", "Plus până la 20"),
        ("Minus bis 20", "Moins jusqu’à 20", "Minus to 20", "Minus până la 20"),
        ("Verdoppeln", "Doubles", "Doubles", "Duble"),
        ("Zahlenraum 50", "Jusqu’à 50", "Up to 50", "Până la 50"),
        ("Rechnen bis 50", "Calculer jusqu’à 50", "Calculate to 50", "Calcul până la 50"),
        ("Zahlenraum 100", "Jusqu’à 100", "Up to 100", "Până la 100"),
        ("Lebendig?", "Vivant ?", "Living?", "Viu?"),
        ("Tiere und Pflanzen", "Animaux et plantes", "Animals and plants", "Animale și plante"),
        ("Jahreszeiten", "Saisons", "Seasons", "Anotimpuri"),
        ("Sinne", "Sens", "Senses", "Simțuri"),
        ("Wasser", "Eau", "Water", "Apă"),
        ("Formen", "Formes", "Shapes", "Forme"),
        ("Messen", "Mesurer", "Measuring", "Măsurăm"),
        ("Mix Natur & Zahl", "Mélange", "Mix review", "Recapitulare"),
    ],
    "shs": [
        ("Familie", "Famille", "Family", "Familie"),
        ("Zuhause", "À la maison", "At home", "Acasă"),
        ("Schule", "École", "School", "Școală"),
        ("Tage", "Jours", "Days", "Zile"),
        ("Jahreszeiten", "Saisons", "Seasons", "Anotimpuri"),
        ("Wetter", "Météo", "Weather", "Vreme"),
        ("Dorf und Stadt", "Village et ville", "Village and city", "Sat și oraș"),
        ("Karte", "Carte", "Map", "Hartă"),
        ("Schweiz", "Suisse", "Switzerland", "Elveția"),
        ("Orte", "Lieux", "Places", "Locuri"),
        ("Berufe", "Métiers", "Jobs", "Meserii"),
        ("Regeln", "Règles", "Rules", "Reguli"),
        ("Früher und heute", "Avant et aujourd’hui", "Then and now", "Apoi și acum"),
        ("Verkehr", "Transports", "Transport", "Transport"),
        ("Nachbarn", "Voisins", "Neighbors", "Vecini"),
        ("Vom Hof", "De la ferme", "From the farm", "De la fermă"),
        ("Natur schützen", "Protéger la nature", "Protect nature", "Protejăm natura"),
        ("Helfen", "Aider", "Helping", "Ajutăm"),
        ("Meine Gemeinde", "Ma commune", "My town", "Comuna mea"),
        ("Zusammen leben", "Vivre ensemble", "Living together", "Împreună"),
    ],
    "arts": [
        ("Farben", "Couleurs", "Colors", "Culori"),
        ("Mehr Farben", "Plus de couleurs", "More colors", "Mai multe culori"),
        ("Formen", "Formes", "Shapes", "Forme"),
        ("Mischen", "Mélanger", "Mixing", "Amestecăm"),
        ("Werkzeuge", "Outils", "Tools", "Unelte"),
        ("Laut und leise", "Fort et doux", "Loud and soft", "Tare și încet"),
        ("Instrumente", "Instruments", "Instruments", "Instrumente"),
        ("Hoch und tief", "Aigu et grave", "High and low", "Înalt și jos"),
        ("Muster", "Motifs", "Patterns", "Modele"),
        ("Gefühle in Kunst", "Émotions", "Feelings in art", "Emocii"),
        ("Malen, singen, bauen", "Peindre, chanter, construire", "Paint, sing, build", "Pictez, cânt, construiesc"),
        ("Rhythmus", "Rythme", "Rhythm", "Ritm"),
        ("Warme Farben", "Couleurs chaudes", "Warm colors", "Culori calde"),
        ("Textur", "Texture", "Texture", "Textură"),
        ("Tanz oder Bild", "Danse ou image", "Dance or picture", "Dans sau imagine"),
        ("Muster fortsetzen", "Continuer le motif", "Continue the pattern", "Continuă modelul"),
        ("Do Re Mi", "Do ré mi", "Do re mi", "Do re mi"),
        ("Tag oder Nacht", "Jour ou nuit", "Day or night", "Zi sau noapte"),
        ("Schmücken", "Décorer", "Decorate", "Decorăm"),
        ("Kunst-Mix", "Mélange arts", "Arts mix", "Amestec arte"),
    ],
    "corps": [
        ("Körperteile", "Parties du corps", "Body parts", "Părți ale corpului"),
        ("Mehr Körper", "Plus de corps", "More body", "Mai mult corp"),
        ("Bewegungen", "Mouvements", "Movements", "Mișcări"),
        ("Links und rechts", "Gauche et droite", "Left and right", "Stânga și dreapta"),
        ("Sport", "Sport", "Sports", "Sport"),
        ("Gesund essen", "Bien manger", "Eat well", "Mâncăm sănătos"),
        ("Wasser trinken", "Boire de l’eau", "Drink water", "Bem apă"),
        ("Schlafen", "Dormir", "Sleep", "Somn"),
        ("Hände waschen", "Se laver les mains", "Wash hands", "Spălăm mâinile"),
        ("Zähne putzen", "Brosser les dents", "Brush teeth", "Spălăm dinții"),
        ("Helm", "Casque", "Helmet", "Cască"),
        ("Im Wasser", "Dans l’eau", "In the water", "În apă"),
        ("Team", "Équipe", "Team", "Echipă"),
        ("Aufwärmen", "Échauffement", "Warm-up", "Încălzire"),
        ("Herz", "Cœur", "Heart", "Inimă"),
        ("Pause", "Pause", "Rest", "Pauză"),
        ("Fairplay", "Fair-play", "Fair play", "Fair-play"),
        ("Kleidung", "Vêtements", "Clothes", "Haine"),
        ("Balance", "Équilibre", "Balance", "Echilibru"),
        ("Bewegungs-Mix", "Mélange", "Movement mix", "Amestec"),
    ],
    "numerique": [
        ("Geräte", "Appareils", "Devices", "Aparate"),
        ("Maus und Tastatur", "Souris et clavier", "Mouse and keyboard", "Mouse și tastatură"),
        ("Klicken und tippen", "Cliquer et taper", "Click and type", "Click și scriu"),
        ("Bilder-Zeichen", "Icônes", "Icons", "Iconițe"),
        ("Ordner", "Dossiers", "Folders", "Dosare"),
        ("Passwort", "Mot de passe", "Password", "Parolă"),
        ("Geheim halten", "Garder secret", "Keep secret", "Păstrăm secret"),
        ("Eine erwachsene Person", "Un adulte", "Ask an adult", "Întreabă un adult"),
        ("Liebe Nachrichten", "Messages gentils", "Kind messages", "Mesaje frumoase"),
        ("Fremde im Netz", "Inconnus en ligne", "Strangers online", "Străini online"),
        ("Bildschirmzeit", "Temps d’écran", "Screen time", "Timp pe ecran"),
        ("Zuerst, dann", "D’abord, ensuite", "First, then", "Mai întâi, apoi"),
        ("Roboter links/rechts", "Robot gauche/droite", "Robot left/right", "Robot stânga/dreapta"),
        ("Dreimal", "Trois fois", "Three times", "De trei ori"),
        ("Strom", "Électricité", "Electricity", "Curent"),
        ("Internet", "Internet", "Internet", "Internet"),
        ("Fotos fragen", "Demander pour les photos", "Ask for photos", "Întreabă pentru poze"),
        ("Stopp wenn Angst", "Stop si peur", "Stop if scared", "Stop dacă ți-e teamă"),
        ("Werkzeug oder Spiel", "Outil ou jeu", "Tool or toy", "Unealtă sau joc"),
        ("Digital-Mix", "Mélange", "Digital mix", "Amestec digital"),
    ],
}


def skill(domain: str, lang: str, level: int) -> str:
    de, fr, en, ro = SKILLS[domain][level - 1]
    return t(lang, de, fr, en, ro)


def pack_shell(domain: str, lang: str, levels: list[dict]) -> dict:
    meta = META[domain]
    return {
        "id": domain,
        "locale": lang,
        "emoji": meta["emoji"],
        "color": meta["color"],
        "title": meta["title"](lang),
        "subtitle": meta["subtitle"](lang),
        "per": meta["per"](lang),
        "levels": levels,
    }


# First this many difficulties are always playable (see LevelUnlock in Dart).
FREE_EXPLORE = 5


def finish_levels(domain: str, lang: str, built: dict[int, list[dict]]) -> list[dict]:
    levels = []
    for n in range(1, 21):
        items = built[n]
        levels.append(
            lvl(
                f"{domain}-l{n}",
                LEVEL_TITLE(lang, n),
                skill(domain, lang, n),
                per_tag(domain, n),
                # Metadata only: Dart unlocks L1–5 freely, then finish-previous.
                0 if n <= FREE_EXPLORE else 1,
                items,
            )
        )
    return levels


# ---------------------------------------------------------------------------
# Langues
# ---------------------------------------------------------------------------

SCHOOL_WORDS = [
    ("book", "📚", ["✏️", "🏫"]),
    ("pencil", "✏️", ["📚", "🍎"]),
    ("school", "🏫", ["🏠", "🌳"]),
    ("apple", "🍎", ["🌸", "⭐"]),
    ("sun", "☀️", ["⭐", "🌸"]),
    ("cat", "🐱", ["🐕", "🐸"]),
    ("dog", "🐕", ["🐱", "🐸"]),
    ("tree", "🌳", ["🏠", "🌸"]),
    ("house", "🏠", ["🏫", "🌳"]),
    ("bag", "🎒", ["📚", "✏️"]),
    ("star", "⭐", ["☀️", "🌼"]),
    ("flower", "🌸", ["🍎", "🌳"]),
    ("water", "💧", ["🍎", "🍞"]),
    ("bread", "🍞", ["🍎", "💧"]),
    ("fish", "🐠", ["🐱", "🐸"]),
    ("bird", "🐦", ["🐠", "🐱"]),
]

WORD = {
    "de": {
        "book": "Buch", "pencil": "Stift", "school": "Schule", "apple": "Apfel",
        "sun": "Sonne", "cat": "Katze", "dog": "Hund", "tree": "Baum",
        "house": "Haus", "bag": "Tasche", "star": "Stern", "flower": "Blume",
        "water": "Wasser", "bread": "Brot", "fish": "Fisch", "bird": "Vogel",
        "red": "rot", "blue": "blau", "yes": "ja", "no": "nein",
        "hello": "Hallo", "thanks": "Danke",
    },
    "fr": {
        "book": "livre", "pencil": "crayon", "school": "école", "apple": "pomme",
        "sun": "soleil", "cat": "chat", "dog": "chien", "tree": "arbre",
        "house": "maison", "bag": "sac", "star": "étoile", "flower": "fleur",
        "water": "eau", "bread": "pain", "fish": "poisson", "bird": "oiseau",
        "red": "rouge", "blue": "bleu", "yes": "oui", "no": "non",
        "hello": "bonjour", "thanks": "merci",
    },
    "en": {
        "book": "book", "pencil": "pencil", "school": "school", "apple": "apple",
        "sun": "sun", "cat": "cat", "dog": "dog", "tree": "tree",
        "house": "house", "bag": "bag", "star": "star", "flower": "flower",
        "water": "water", "bread": "bread", "fish": "fish", "bird": "bird",
        "red": "red", "blue": "blue", "yes": "yes", "no": "no",
        "hello": "hello", "thanks": "thanks",
    },
    "ro": {
        "book": "carte", "pencil": "creion", "school": "școală", "apple": "măr",
        "sun": "soare", "cat": "pisică", "dog": "câine", "tree": "copac",
        "house": "casă", "bag": "ghiozdan", "star": "stea", "flower": "floare",
        "water": "apă", "bread": "pâine", "fish": "pește", "bird": "pasăre",
        "red": "roșu", "blue": "albastru", "yes": "da", "no": "nu",
        "hello": "salut", "thanks": "mulțumesc",
    },
}

L2_KEYS = ["sun", "cat", "house", "apple", "tree", "water"]
L3_KEYS = ["book", "dog", "flower", "star", "bread", "bird"]


def _picture_row(lang: str, key: str, emoji: str, distractors: list[str], i: int, listen: bool) -> dict:
    word = WORD[lang][key]
    pictures = [emoji, *distractors]
    correct = (i - 1) % len(pictures)
    pictures[0], pictures[correct] = pictures[correct], pictures[0]
    prompt = t(lang, "Hör zu und tippe", "Écoute et touche", "Listen and tap", "Ascultă și atinge") if listen else word
    return ex(
        f"{lang}-langues-{key}-{i:02d}{'-l' if listen else ''}",
        prompt,
        word,
        pictures,
        correct,
        kind="vocab",
    )


def langues_exercises(lang: str) -> dict[int, list[dict]]:
    lex = WORD[lang]
    built: dict[int, list[dict]] = {}

    # 1–2 picture match (school language). Level 1 starts with book for tests.
    # Second item of L1 is typed so the keyboard is on the first unlocked level,
    # one picture-tap after the opener — not buried at the end or in L4+.
    for n, chunk in ((1, SCHOOL_WORDS[:6]), (2, SCHOOL_WORDS[6:12])):
        items = []
        for i, (key, emoji, distractors) in enumerate(chunk, start=1):
            items.append(_picture_row(lang, key, emoji, distractors, i, listen=False))
        built[n] = items

    cat_key, cat_emoji, _ = SCHOOL_WORDS[5]
    cat_word = lex[cat_key]
    type_l1 = typed(
        f"{lang}-langues-l1-type",
        *write_word(lang, cat_word),
        [cat_word],
        kind="vocab",
        visual=cat_emoji,
    )
    built[1] = [built[1][0], type_l1, *built[1][1:5]]
    dog_key, dog_emoji, _ = SCHOOL_WORDS[6]
    dog_word = lex[dog_key]
    built[2][0] = typed(
        f"{lang}-langues-l2-type",
        *write_word(lang, dog_word),
        [dog_word],
        kind="vocab",
        visual=dog_emoji,
    )

    # 3 listen
    built[3] = [
        _picture_row(lang, key, emoji, distractors, i, listen=True)
        for i, (key, emoji, distractors) in enumerate(SCHOOL_WORDS[:5], start=1)
    ]

    # 4 first letters (type)
    keys4 = ["book", "sun", "cat", "dog", "tree"]
    items = []
    for i, key in enumerate(keys4, start=1):
        word = lex[key]
        items.append(typed(
            f"{lang}-langues-l4-{i:02d}",
            t(lang, f"Erster Buchstabe von {word}", f"Première lettre de {word}",
              f"First letter of {word}", f"Prima literă din {word}"),
            t(lang, f"Schreib den ersten Buchstaben von {word}", f"Écris la première lettre de {word}",
              f"Type the first letter of {word}", f"Scrie prima literă din {word}"),
            [word[0]],
            kind="vocab",
        ))
    built[4] = items

    # 5–6 type school words
    for n, keys in ((5, ["cat", "sun", "dog", "book", "tree"]), (6, ["school", "house", "apple", "flower", "water"])):
        items = []
        for i, key in enumerate(keys, start=1):
            word = lex[key]
            emoji = next(e for k, e, _ in SCHOOL_WORDS if k == key)
            prompt, tts = write_word(lang, word)
            items.append(typed(
                f"{lang}-langues-l{n}-{i:02d}", prompt, tts, [word],
                kind="vocab", visual=emoji,
            ))
        built[n] = items

    # 7 accents / special letters
    special = {
        "de": [("ä", "ä"), ("ö", "ö"), ("ü", "ü"), ("Schule", "Schule"), ("Äpfel", "Äpfel")],
        "fr": [("école", "école"), ("étoile", "étoile"), ("fleur", "fleur"), ("où", "où"), ("été", "été")],
        "en": [("school", "school"), ("apple", "apple"), ("flower", "flower"), ("house", "house"), ("water", "water")],
        "ro": [("școală", "școală"), ("câine", "câine"), ("măr", "măr"), ("apă", "apă"), ("pâine", "pâine")],
    }[lang]
    built[7] = [
        typed(f"{lang}-langues-l7-{i:02d}", *write_word(lang, word), [ans], kind="vocab")
        for i, (word, ans) in enumerate(special, start=1)
    ]

    # 8 animals choice, 9 food type
    built[8] = [
        _picture_row(lang, key, emoji, d, i, False)
        for i, (key, emoji, d) in enumerate([
            ("cat", "🐱", ["🐕", "🐦"]),
            ("dog", "🐕", ["🐱", "🐠"]),
            ("fish", "🐠", ["🐦", "🐱"]),
            ("bird", "🐦", ["🐠", "🐕"]),
            ("apple", "🍎", ["🐱", "🌳"]),
        ], start=1)
    ]
    built[9] = [
        typed(f"{lang}-langues-l9-{i:02d}", *write_word(lang, lex[k]), [lex[k]], kind="vocab", visual=v)
        for i, (k, v) in enumerate([("apple", "🍎"), ("bread", "🍞"), ("water", "💧"), ("fish", "🐠"), ("flower", "🌸")], start=1)
    ]

    # 10 longer type
    built[10] = [
        typed(f"{lang}-langues-l10-{i:02d}", *write_word(lang, lex[k]), [lex[k]], kind="vocab")
        for i, k in enumerate(["school", "flower", "pencil", "thanks", "hello"], start=1)
    ]

    # 11 opposites (choice)
    pairs = [
        (lex["yes"], lex["no"]),
        (lex["red"], lex["blue"]),
        (t(lang, "gross", "grand", "big", "mare"), t(lang, "klein", "petit", "small", "mic")),
        (t(lang, "tag", "jour", "day", "zi"), t(lang, "nacht", "nuit", "night", "noapte")),
        (t(lang, "heiss", "chaud", "hot", "cald"), t(lang, "kalt", "froid", "cold", "rece")),
    ]
    built[11] = []
    for i, (a, b) in enumerate(pairs, start=1):
        prompt = t(lang, f"Gegenteil von {a}?", f"Contraire de {a} ?", f"Opposite of {a}?", f"Contrarul lui {a}?")
        built[11].append(ex(f"{lang}-langues-l11-{i:02d}", prompt, prompt, [b, a, lex["sun"]], 0, kind="quiz"))

    # 12 listen hello/thanks
    built[12] = [
        ex(f"{lang}-langues-l12-{i:02d}",
           t(lang, "Hör zu", "Écoute", "Listen", "Ascultă"),
           lex[k], [lex[k], lex[alt], lex["red"]], 0, kind="vocab")
        for i, (k, alt) in enumerate([("hello", "thanks"), ("thanks", "hello"), ("yes", "no"), ("no", "yes"), ("sun", "cat")], start=1)
    ]

    l2_lang = "fr" if lang == "de" else "de"
    l3_lang = "fr" if lang == "en" else "en"

    def other_vocab(n: int, keys: list[str], src: str, mode: str) -> list[dict]:
        items = []
        for i, key in enumerate(keys, start=1):
            word = WORD[src][key]
            emoji = next(e for k, e, _ in SCHOOL_WORDS if k == key)
            if mode == "type":
                prompt, tts = write_word(lang, word)
                items.append(typed(f"{lang}-langues-l{n}-{i:02d}", prompt, tts, [word], kind="vocab", visual=emoji))
            elif mode == "listen":
                items.append(_picture_row(src, key, emoji, ["⭐", "🌳"], i, True) | {"id": f"{lang}-langues-l{n}-{i:02d}"})
                items[-1]["prompt"] = t(lang, "Hör zu und tippe", "Écoute et touche", "Listen and tap", "Ascultă și atinge")
                items[-1]["promptTts"] = word
            else:
                items.append(ex(
                    f"{lang}-langues-l{n}-{i:02d}", word, word,
                    [emoji, "⭐", "🌳"], 0, kind="vocab",
                ))
        return items

    built[13] = other_vocab(13, L2_KEYS[:5], l2_lang, "choice")
    built[14] = other_vocab(14, L2_KEYS, l2_lang, "choice")
    built[15] = other_vocab(15, L2_KEYS[:5], l2_lang, "type")
    built[16] = other_vocab(16, L2_KEYS[:5], l2_lang, "listen")
    built[17] = other_vocab(17, L3_KEYS[:5], l3_lang, "choice")
    built[18] = other_vocab(18, L3_KEYS, l3_lang, "choice")
    built[19] = other_vocab(19, L3_KEYS[:5], l3_lang, "type")
    built[20] = other_vocab(20, ["book", "cat", "sun", "house", "tree"], lang, "type")
    return built


# ---------------------------------------------------------------------------
# Math + nature
# ---------------------------------------------------------------------------

COUNT_NOUN = {
    "de": {"apple": "Äpfel", "star": "Sterne", "flower": "Blumen", "dot": "Punkte", "frog": "Frösche"},
    "fr": {"apple": "pommes", "star": "étoiles", "flower": "fleurs", "dot": "points", "frog": "grenouilles"},
    "en": {"apple": "apples", "star": "stars", "flower": "flowers", "dot": "dots", "frog": "frogs"},
    "ro": {"apple": "mere", "star": "stele", "flower": "flori", "dot": "puncte", "frog": "broaște"},
}


def count_ex(lang: str, eid: str, emoji: str, n: int, noun_key: str, mode: str = "choice") -> dict:
    noun = COUNT_NOUN[lang][noun_key]
    if mode == "type":
        return typed(
            eid, how_many(lang), count_tts(lang, noun), [str(n)],
            keyboard="number", kind="counting", items=[emoji] * n,
        )
    choices, correct = nearby(n)
    return ex(
        eid, how_many(lang), count_tts(lang, noun), choices, correct,
        kind="counting", items=[emoji] * n,
    )


def add_ex(lang: str, eid: str, a: int, b: int, mode: str = "choice") -> dict:
    s = a + b
    if mode == "type":
        return typed(eid, f"{a} + {b} = ?", add_tts(lang, a, b), [str(s)], keyboard="number", kind="math")
    choices, correct = nearby(s)
    return ex(eid, f"{a} + {b} = ?", add_tts(lang, a, b), choices, correct, kind="math")


def sub_ex(lang: str, eid: str, a: int, b: int, mode: str = "choice") -> dict:
    s = a - b
    if mode == "type":
        return typed(eid, f"{a} − {b} = ?", sub_tts(lang, a, b), [str(s)], keyboard="number", kind="math")
    choices, correct = nearby(s)
    return ex(eid, f"{a} − {b} = ?", sub_tts(lang, a, b), choices, correct, kind="math")


def math_exercises(lang: str) -> dict[int, list[dict]]:
    e = f"{lang}-msn"
    built: dict[int, list[dict]] = {
        1: [
            add_ex(lang, f"{e}-l1-01", 1, 1),
            count_ex(lang, f"{e}-l1-02", "🌼", 3, "flower", "type"),
            count_ex(lang, f"{e}-l1-03", "🍎", 2, "apple"),
            count_ex(lang, f"{e}-l1-04", "⭐", 1, "star"),
            add_ex(lang, f"{e}-l1-05", 2, 1),
        ],
        2: [
            count_ex(lang, f"{e}-l2-01", "🍎", 4, "apple"),
            count_ex(lang, f"{e}-l2-02", "⭐", 5, "star"),
            count_ex(lang, f"{e}-l2-03", "🐸", 2, "frog"),
            count_ex(lang, f"{e}-l2-04", "🔵", 3, "dot", "type"),
            add_ex(lang, f"{e}-l2-05", 2, 2),
        ],
        3: [
            count_ex(lang, f"{e}-l3-01", "🍎", 7, "apple"),
            count_ex(lang, f"{e}-l3-02", "⭐", 8, "star"),
            count_ex(lang, f"{e}-l3-03", "🌼", 10, "flower"),
            count_ex(lang, f"{e}-l3-04", "🔵", 6, "dot", "type"),
            count_ex(lang, f"{e}-l3-05", "🐸", 9, "frog"),
        ],
        4: [add_ex(lang, f"{e}-l4-{i:02d}", a, b, "type" if i == 5 else "choice")
            for i, (a, b) in enumerate([(1, 2), (2, 2), (3, 1), (4, 1), (2, 3)], start=1)],
        5: [add_ex(lang, f"{e}-l5-{i:02d}", a, b, "type" if i % 2 == 0 else "choice")
            for i, (a, b) in enumerate([(4, 3), (5, 2), (6, 4), (7, 2), (3, 5)], start=1)],
        6: [sub_ex(lang, f"{e}-l6-{i:02d}", a, b, "type" if i == 3 else "choice")
            for i, (a, b) in enumerate([(5, 2), (6, 1), (8, 3), (9, 4), (7, 5)], start=1)],
        7: [add_ex(lang, f"{e}-l7-{i:02d}", a, b, "type" if i == 4 else "choice")
            for i, (a, b) in enumerate([(10, 4), (8, 5), (7, 7), (11, 3), (9, 6)], start=1)],
        8: [sub_ex(lang, f"{e}-l8-{i:02d}", a, b, "type" if i == 2 else "choice")
            for i, (a, b) in enumerate([(12, 4), (15, 6), (11, 3), (14, 5), (18, 9)], start=1)],
        9: [add_ex(lang, f"{e}-l9-{i:02d}", a, a, "type" if i >= 4 else "choice")
            for i, a in enumerate([2, 4, 5, 6, 8], start=1)],
        10: [
            ex(f"{e}-l10-01", "20 + 10 = ?", add_tts(lang, 20, 10), *nearby(30)[::-1] if False else nearby(30), kind="math")[0]
            if False else add_ex(lang, f"{e}-l10-01", 20, 10),
            add_ex(lang, f"{e}-l10-02", 30, 5),
            add_ex(lang, f"{e}-l10-03", 40, 4, "type"),
            sub_ex(lang, f"{e}-l10-04", 20, 5),
            typed(f"{e}-l10-05", "25", type_number_tts(lang, t(lang, "fünfundzwanzig", "vingt-cinq", "twenty-five", "douăzeci și cinci")),
                  ["25"], keyboard="number", kind="math"),
        ],
        11: [
            add_ex(lang, f"{e}-l11-01", 21, 8),
            sub_ex(lang, f"{e}-l11-02", 40, 10),
            add_ex(lang, f"{e}-l11-03", 15, 15, "type"),
            sub_ex(lang, f"{e}-l11-04", 33, 3),
            add_ex(lang, f"{e}-l11-05", 12, 18),
        ],
        12: [
            add_ex(lang, f"{e}-l12-01", 50, 20),
            add_ex(lang, f"{e}-l12-02", 40, 40),
            typed(f"{e}-l12-03", "100", type_number_tts(lang, t(lang, "hundert", "cent", "one hundred", "o sută")),
                  ["100"], keyboard="number", kind="math"),
            sub_ex(lang, f"{e}-l12-04", 90, 10),
            add_ex(lang, f"{e}-l12-05", 60, 7, "type"),
        ],
    }

    living_q = t(lang, "Lebt das?", "Est-ce vivant ?", "Is it living?", "Este viu?")
    built[13] = [
        ex(f"{e}-l13-01", living_q, living_q, [t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")], 0, kind="quiz", visual="🐱"),
        ex(f"{e}-l13-02", living_q, living_q, [t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")], 1, kind="quiz", visual="🚗"),
        ex(f"{e}-l13-03", living_q, living_q, [t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")], 0, kind="quiz", visual="🌳"),
        ex(f"{e}-l13-04", living_q, living_q, [t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")], 1, kind="quiz", visual="🪨"),
        typed(
            f"{e}-l13-05",
            t(lang, "Schreib ja oder nein: 🐱", "Écris oui ou non : 🐱", "Type yes or no: 🐱", "Scrie da sau nu: 🐱"),
            living_q,
            [t(lang, "ja", "oui", "yes", "da")],
            kind="quiz",
            visual="🐱",
        ),
    ]

    plant_or = t(lang, "Pflanze oder Tier?", "Plante ou animal ?", "Plant or animal?", "Plantă sau animal?")
    plant, animal = t(lang, "Pflanze", "plante", "plant", "plantă"), t(lang, "Tier", "animal", "animal", "animal")
    built[14] = [
        ex(f"{e}-l14-01", plant_or, plant_or, [plant, animal], 1, kind="quiz", visual="🐱"),
        ex(f"{e}-l14-02", plant_or, plant_or, [plant, animal], 0, kind="quiz", visual="🌳"),
        ex(f"{e}-l14-03", plant_or, plant_or, [plant, animal], 1, kind="quiz", visual="🐸"),
        ex(f"{e}-l14-04", plant_or, plant_or, [plant, animal], 0, kind="quiz", visual="🌼"),
        typed(f"{e}-l14-05", t(lang, "Schreib: Pflanze oder Tier — 🌼", "Écris : plante ou animal — 🌼",
                               "Type: plant or animal — 🌼", "Scrie: plantă sau animal — 🌼"),
              plant_or, [plant], kind="quiz", visual="🌼"),
    ]

    seasons = [
        (t(lang, "Sommer", "été", "summer", "vară"), "☀️"),
        (t(lang, "Winter", "hiver", "winter", "iarnă"), "❄️"),
        (t(lang, "Frühling", "printemps", "spring", "primăvară"), "🌸"),
        (t(lang, "Herbst", "automne", "autumn", "toamnă"), "🍂"),
    ]
    q_season = t(lang, "Welche Jahreszeit?", "Quelle saison ?", "Which season?", "Ce anotimp?")
    built[15] = [
        ex(f"{e}-l15-{i:02d}", q_season, q_season, [name, seasons[(i) % 4][0], seasons[(i + 1) % 4][0]], 0, kind="quiz", visual=icon)
        for i, (name, icon) in enumerate(seasons, start=1)
    ]
    built[15].append(typed(
        f"{e}-l15-05", *write_word(lang, seasons[1][0]), [seasons[1][0]], kind="quiz", visual="❄️",
    ))

    senses = [
        (t(lang, "sehen", "voir", "see", "văd"), "👀"),
        (t(lang, "hören", "entendre", "hear", "aud"), "👂"),
        (t(lang, "riechen", "sentir", "smell", "miros"), "👃"),
        (t(lang, "schmecken", "goûter", "taste", "gust"), "👅"),
    ]
    q_sense = t(lang, "Welcher Sinn?", "Quel sens ?", "Which sense?", "Ce simț?")
    built[16] = [
        ex(f"{e}-l16-{i:02d}", q_sense, q_sense, [name, senses[(i) % 4][0], senses[(i + 1) % 4][0]], 0, kind="quiz", visual=icon)
        for i, (name, icon) in enumerate(senses, start=1)
    ]
    built[16].append(typed(f"{e}-l16-05", *write_word(lang, senses[0][0]), [senses[0][0]], kind="quiz"))

    ice = t(lang, "Eis", "glace", "ice", "gheață")
    steam = t(lang, "Dampf", "vapeur", "steam", "abur")
    water = t(lang, "Wasser", "eau", "water", "apă")
    q_water = t(lang, "Wasser, Eis oder Dampf?", "Eau, glace ou vapeur ?", "Water, ice or steam?", "Apă, gheață sau abur?")
    built[17] = [
        ex(f"{e}-l17-01", q_water, q_water, [water, ice, steam], 0, kind="quiz", visual="💧"),
        ex(f"{e}-l17-02", q_water, q_water, [water, ice, steam], 1, kind="quiz", visual="🧊"),
        ex(f"{e}-l17-03", q_water, q_water, [water, ice, steam], 2, kind="quiz", visual="♨️"),
        typed(f"{e}-l17-04", *write_word(lang, water), [water], kind="quiz", visual="💧"),
        add_ex(lang, f"{e}-l17-05", 2, 3),
    ]

    shapes = [
        (t(lang, "Kreis", "cercle", "circle", "cerc"), "⭕"),
        (t(lang, "Quadrat", "carré", "square", "pătrat"), "⬜"),
        (t(lang, "Dreieck", "triangle", "triangle", "triunghi"), "🔺"),
        (t(lang, "Rechteck", "rectangle", "rectangle", "dreptunghi"), "▬"),
    ]
    q_shape = t(lang, "Welche Form?", "Quelle forme ?", "Which shape?", "Ce formă?")
    built[18] = [
        ex(f"{e}-l18-{i:02d}", q_shape, q_shape, [name, shapes[(i) % 4][0], shapes[(i + 1) % 4][0]], 0, kind="quiz", visual=icon)
        for i, (name, icon) in enumerate(shapes, start=1)
    ]
    built[18].append(typed(f"{e}-l18-05", *write_word(lang, shapes[0][0]), [shapes[0][0]], kind="quiz", visual="⭕"))

    longer = t(lang, "Was ist länger?", "Qui est plus long ?", "Which is longer?", "Ce e mai lung?")
    built[19] = [
        ex(f"{e}-l19-01", longer, longer, ["—", "-"], 0, kind="quiz"),
        ex(f"{e}-l19-02", t(lang, "Was ist schwerer?", "Qui est plus lourd ?", "Which is heavier?", "Ce e mai greu?"),
           t(lang, "Was ist schwerer, ein Stein oder eine Feder?", "Qui est plus lourd, une pierre ou une plume ?",
             "Which is heavier, a rock or a feather?", "Ce e mai greu, o piatră sau o pană?"),
           [t(lang, "Stein", "pierre", "rock", "piatră"), t(lang, "Feder", "plume", "feather", "pană")], 0, kind="quiz"),
        typed(f"{e}-l19-03", "10 + 10 = ?", add_tts(lang, 10, 10), ["20"], keyboard="number", kind="math"),
        ex(f"{e}-l19-04", t(lang, "Wie viele Zentimeter hat ein Dezimeter?", "Combien de centimètres dans un décimètre ?",
                            "How many centimetres in a decimetre?", "Câți centimetri are un decimetru?"),
           t(lang, "Ein Dezimeter hat zehn Zentimeter", "Un décimètre a dix centimètres",
             "A decimetre has ten centimetres", "Un decimetru are zece centimetri"),
           ["10", "100", "1"], 0, kind="quiz"),
        typed(f"{e}-l19-05", "8 − 3 = ?", sub_tts(lang, 8, 3), ["5"], keyboard="number", kind="math"),
    ]

    built[20] = [
        add_ex(lang, f"{e}-l20-01", 9, 8),
        sub_ex(lang, f"{e}-l20-02", 16, 7, "type"),
        ex(f"{e}-l20-03", living_q, living_q, [t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")], 0, kind="quiz", visual="🐠"),
        typed(f"{e}-l20-04", *write_word(lang, t(lang, "Kreis", "cercle", "circle", "cerc")),
              [t(lang, "Kreis", "cercle", "circle", "cerc")], kind="quiz"),
        count_ex(lang, f"{e}-l20-05", "⭐", 5, "star", "type"),
    ]
    return built


# ---------------------------------------------------------------------------
# Shared quiz helper
# ---------------------------------------------------------------------------

def quiz_choice(lang: str, eid: str, prompt: str, tts: str, choices: list[str], correct: int, visual: str | None = None) -> dict:
    extra = {"kind": "quiz"}
    if visual:
        extra["visual"] = visual
    return ex(eid, prompt, tts, choices, correct, **extra)


# ---------------------------------------------------------------------------
# SHS / Arts / Corps / Numerique — compact tables
# ---------------------------------------------------------------------------

def table_levels(lang: str, domain: str, rows: dict[int, list[dict]]) -> dict[int, list[dict]]:
    return rows


def shs_exercises(lang: str) -> dict[int, list[dict]]:
    e = f"{lang}-shs"
    yes, no = t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")
    mama = t(lang, "Mama", "maman", "mum", "mama")
    papa = t(lang, "Papa", "papa", "dad", "tata")
    me = t(lang, "ich", "moi", "me", "eu")
    home = t(lang, "Haus", "maison", "house", "casă")
    school = t(lang, "Schule", "école", "school", "școală")
    shop = t(lang, "Laden", "magasin", "shop", "magazin")
    park = t(lang, "Park", "parc", "park", "parc")
    rain = t(lang, "Regen", "pluie", "rain", "ploaie")
    sun = t(lang, "Sonne", "soleil", "sun", "soare")
    snow = t(lang, "Schnee", "neige", "snow", "zăpadă")
    ch = t(lang, "Schweiz", "Suisse", "Switzerland", "Elveția")
    flag_q = t(lang, "Welche Flagge ist die Schweiz?", "Quel drapeau est la Suisse ?", "Which flag is Switzerland?", "Care steag e Elveția?")
    mountain = t(lang, "Berg", "montagne", "mountain", "munte")
    lake = t(lang, "See", "lac", "lake", "lac")
    river = t(lang, "Fluss", "rivière", "river", "râu")
    today = t(lang, "heute", "aujourd’hui", "today", "azi")
    yesterday = t(lang, "gestern", "hier", "yesterday", "ieri")
    doctor = t(lang, "Ärztin", "docteure", "doctor", "doctoriță")
    baker = t(lang, "Bäcker", "boulanger", "baker", "brutar")
    teacher = t(lang, "Lehrerin", "enseignante", "teacher", "învățătoare")
    share = t(lang, "teilen", "partager", "share", "împărțim")
    hit = t(lang, "schlagen", "frapper", "hit", "lovim")
    bike = t(lang, "Velo", "vélo", "bike", "bicicletă")
    bus = t(lang, "Bus", "bus", "bus", "autobuz")
    train = t(lang, "Zug", "train", "train", "tren")
    france = t(lang, "Frankreich", "France", "France", "Franța")
    milk = t(lang, "Milch", "lait", "milk", "lapte")
    recycle = t(lang, "recyclen", "recycler", "recycle", "reciclăm")
    help_w = t(lang, "helfen", "aider", "help", "ajutăm")

    built: dict[int, list[dict]] = {
        1: [
            quiz_choice(lang, f"{e}-l1-01", t(lang, "Wer ist das?", "Qui est-ce ?", "Who is this?", "Cine e?"), mama, [mama, school, bike], 0, "👩"),
            quiz_choice(lang, f"{e}-l1-02", t(lang, "Wer ist das?", "Qui est-ce ?", "Who is this?", "Cine e?"), papa, [papa, park, train], 0, "👨"),
            quiz_choice(lang, f"{e}-l1-03", t(lang, "Familie: wer fehlt?", "Famille : qui manque ?", "Family: who is missing?", "Familie: cine lipsește?"),
                        me, [me, ch, lake], 0, "🧒"),
            typed(f"{e}-l1-04", *write_word(lang, mama), [mama], kind="quiz"),
            quiz_choice(lang, f"{e}-l1-05", t(lang, "Gehört das zur Familie?", "Ça fait partie de la famille ?", "Is this family?", "Face parte din familie?"),
                        t(lang, "Hund kann zur Familie gehören", "Un chien peut faire partie de la famille", "A dog can be family", "Un câine poate fi familie"),
                        [yes, no], 0, "🐕"),
        ],
        2: [
            quiz_choice(lang, f"{e}-l2-01", t(lang, "Wo schläft man?", "Où dort-on ?", "Where do we sleep?", "Unde dormim?"),
                        t(lang, "im Bett", "dans le lit", "in bed", "în pat"), [home, school, shop], 0, "🛏️"),
            quiz_choice(lang, f"{e}-l2-02", t(lang, "Wo kocht man?", "Où cuisine-t-on ?", "Where do we cook?", "Unde gătim?"),
                        t(lang, "in der Küche", "dans la cuisine", "in the kitchen", "în bucătărie"),
                        [t(lang, "Küche", "cuisine", "kitchen", "bucătărie"), school, park], 0, "🍳"),
            typed(f"{e}-l2-03", *write_word(lang, home), [home], kind="quiz", visual="🏠"),
            quiz_choice(lang, f"{e}-l2-04", t(lang, "Tür oder Fenster?", "Porte ou fenêtre ?", "Door or window?", "Ușă sau fereastră?"),
                        t(lang, "Fenster", "fenêtre", "window", "fereastră"),
                        [t(lang, "Fenster", "fenêtre", "window", "fereastră"), t(lang, "Tür", "porte", "door", "ușă")], 0, "🪟"),
            quiz_choice(lang, f"{e}-l2-05", t(lang, "Wo wohnen wir?", "Où habitons-nous ?", "Where do we live?", "Unde locuim?"),
                        home, [home, train, doctor], 0, "🏠"),
        ],
    }

    day = t(lang, "Montag", "lundi", "Monday", "luni")
    # Fill remaining SHS levels with compact loops
    place_q = t(lang, "Wohin gehöre ich?", "Où est-ce ?", "Where is this?", "Unde e?")
    built[3] = [
        quiz_choice(lang, f"{e}-l3-01", place_q, school, [school, home, shop], 0, "🏫"),
        quiz_choice(lang, f"{e}-l3-02", t(lang, "Wer unterrichtet?", "Qui enseigne ?", "Who teaches?", "Cine predă?"),
                    teacher, [teacher, baker, bus], 0, "👩‍🏫"),
        typed(f"{e}-l3-03", *write_word(lang, school), [school], kind="quiz", visual="🏫"),
        quiz_choice(lang, f"{e}-l3-04", t(lang, "Was braucht man in der Schule?", "De quoi a-t-on besoin à l’école ?",
                                         "What do you need at school?", "Ce trebuie la școală?"),
                    t(lang, "Stift", "crayon", "pencil", "creion"),
                    [t(lang, "Stift", "crayon", "pencil", "creion"), bike, snow], 0, "✏️"),
        quiz_choice(lang, f"{e}-l3-05", t(lang, "Pause: wo spielen?", "Récré : où jouer ?", "Break: where to play?", "Pauză: unde ne jucăm?"),
                    park, [park, baker, train], 0, "🛝"),
    ]
    built[4] = [
        quiz_choice(lang, f"{e}-l4-01", t(lang, "Welcher Tag kommt zuerst in der Woche (DE/CH Schule oft Montag)?",
                                         "Quel jour commence souvent la semaine d’école ?",
                                         "Which day often starts the school week?",
                                         "Ce zi începe adesea săptămâna de școală?"),
                    day, [day, yesterday, snow], 0),
        quiz_choice(lang, f"{e}-l4-02", t(lang, "Heute oder gestern?", "Aujourd’hui ou hier ?", "Today or yesterday?", "Azi sau ieri?"),
                    today, [today, yesterday], 0),
        typed(f"{e}-l4-03", *write_word(lang, today), [today], kind="quiz"),
        quiz_choice(lang, f"{e}-l4-04", t(lang, "Was war vorher?", "Qu’est-ce qui était avant ?", "What was before?", "Ce a fost înainte?"),
                    yesterday, [yesterday, today], 0),
        quiz_choice(lang, f"{e}-l4-05", t(lang, "Wie viele Tage hat eine Woche?", "Combien de jours dans une semaine ?",
                                         "How many days in a week?", "Câte zile are o săptămână?"),
                    t(lang, "Eine Woche hat sieben Tage", "Une semaine a sept jours",
                      "A week has seven days", "O săptămână are șapte zile"),
                    ["5", "7", "10"], 1),
    ]
    # Fix kind on last - quiz_choice already sets quiz. The 7 is via quiz_choice... I used ex-like via quiz_choice. Good.

    season_pairs = [
        (t(lang, "Sommer", "été", "summer", "vară"), "☀️"),
        (t(lang, "Winter", "hiver", "winter", "iarnă"), "❄️"),
        (t(lang, "Frühling", "printemps", "spring", "primăvară"), "🌸"),
        (t(lang, "Herbst", "automne", "autumn", "toamnă"), "🍂"),
        (sun, "☀️"),
    ]
    built[5] = [
        quiz_choice(lang, f"{e}-l5-{i:02d}", t(lang, "Jahreszeit?", "Saison ?", "Season?", "Anotimp?"), name, [name, rain, shop], 0, icon)
        for i, (name, icon) in enumerate(season_pairs[:4], start=1)
    ]
    built[5].append(typed(f"{e}-l5-05", *write_word(lang, season_pairs[0][0]), [season_pairs[0][0]], kind="quiz"))

    built[6] = [
        quiz_choice(lang, f"{e}-l6-01", t(lang, "Welches Wetter?", "Quel temps ?", "What weather?", "Ce vreme?"), rain, [rain, baker, home], 0, "🌧️"),
        quiz_choice(lang, f"{e}-l6-02", t(lang, "Welches Wetter?", "Quel temps ?", "What weather?", "Ce vreme?"), sun, [sun, snow, bus], 0, "☀️"),
        quiz_choice(lang, f"{e}-l6-03", t(lang, "Welches Wetter?", "Quel temps ?", "What weather?", "Ce vreme?"), snow, [snow, rain, shop], 0, "❄️"),
        typed(f"{e}-l6-04", *write_word(lang, rain), [rain], kind="quiz", visual="🌧️"),
        quiz_choice(lang, f"{e}-l6-05", t(lang, "Braucht man einen Schirm?", "Faut-il un parapluie ?", "Need an umbrella?", "Trebuie umbrelă?"),
                    rain, [yes, no], 0, "🌧️"),
    ]
    village = t(lang, "Dorf", "village", "village", "sat")
    city = t(lang, "Stadt", "ville", "city", "oraș")
    built[7] = [
        quiz_choice(lang, f"{e}-l7-01", t(lang, "Viele Häuser und Busse?", "Beaucoup de maisons et de bus ?", "Many houses and buses?", "Multe case și autobuze?"),
                    city, [city, village], 0, "🏙️"),
        quiz_choice(lang, f"{e}-l7-02", t(lang, "Wenig Häuser, Felder?", "Peu de maisons, des champs ?", "Few houses, fields?", "Puține case, câmpuri?"),
                    village, [village, city], 0, "🏡"),
        typed(f"{e}-l7-03", *write_word(lang, city), [city], kind="quiz"),
        quiz_choice(lang, f"{e}-l7-04", place_q, shop, [shop, mountain, lake], 0, "🏪"),
        quiz_choice(lang, f"{e}-l7-05", place_q, park, [park, baker, train], 0, "🌳"),
    ]
    built[8] = [
        quiz_choice(lang, f"{e}-l8-01", t(lang, "Was ist das auf der Karte?", "Qu’est-ce que c’est sur la carte ?", "What is this on the map?", "Ce e pe hartă?"),
                    mountain, [mountain, shop, baker], 0, "⛰️"),
        quiz_choice(lang, f"{e}-l8-02", t(lang, "Was ist das auf der Karte?", "Qu’est-ce que c’est sur la carte ?", "What is this on the map?", "Ce e pe hartă?"),
                    lake, [lake, bus, school], 0, "🏞️"),
        quiz_choice(lang, f"{e}-l8-03", t(lang, "Was fliesst?", "Qu’est-ce qui coule ?", "What flows?", "Ce curge?"),
                    river, [river, home, flag_q], 0, "〰️"),
        typed(f"{e}-l8-04", *write_word(lang, lake), [lake], kind="quiz"),
        quiz_choice(lang, f"{e}-l8-05", t(lang, "Alpen sind…", "Les Alpes sont…", "The Alps are…", "Alpii sunt…"),
                    mountain, [mountain, shop, milk], 0, "🏔️"),
    ]
    built[9] = [
        quiz_choice(lang, f"{e}-l9-01", flag_q, flag_q, ["🇨🇭", "🇫🇷", "🇩🇪"], 0),
        quiz_choice(lang, f"{e}-l9-02", t(lang, "Land?", "Pays ?", "Country?", "Țară?"), ch, [ch, france, baker], 0, "🇨🇭"),
        typed(f"{e}-l9-03", *write_word(lang, ch), [ch], kind="quiz", visual="🇨🇭"),
        quiz_choice(lang, f"{e}-l9-04", t(lang, "Hauptstadt (einfach): Bern?", "Capitale (simple) : Berne ?", "Capital (simple): Bern?", "Capitală (simplu): Berna?"),
                    yes, [yes, no], 0),
        quiz_choice(lang, f"{e}-l9-05", t(lang, "Gibt es Berge in der Schweiz?", "Y a-t-il des montagnes en Suisse ?",
                                         "Are there mountains in Switzerland?", "Sunt munți în Elveția?"),
                    yes, [yes, no], 0, "🏔️"),
    ]
    built[10] = [
        quiz_choice(lang, f"{e}-l10-01", place_q, school, [school, lake, mountain], 0, "🏫"),
        quiz_choice(lang, f"{e}-l10-02", place_q, shop, [shop, river, train], 0, "🏪"),
        quiz_choice(lang, f"{e}-l10-03", place_q, park, [park, baker, snow], 0, "🌳"),
        typed(f"{e}-l10-04", *write_word(lang, park), [park], kind="quiz", visual="🌳"),
        quiz_choice(lang, f"{e}-l10-05", t(lang, "Wo kauft man Brot?", "Où achète-t-on du pain ?", "Where do you buy bread?", "Unde cumperi pâine?"),
                    shop, [shop, lake, mountain], 0, "🍞"),
    ]
    built[11] = [
        quiz_choice(lang, f"{e}-l11-01", t(lang, "Wer backt Brot?", "Qui fait le pain ?", "Who bakes bread?", "Cine coace pâinea?"),
                    baker, [baker, doctor, train], 0, "🥖"),
        quiz_choice(lang, f"{e}-l11-02", t(lang, "Wer hilft wenn man krank ist?", "Qui aide si on est malade ?", "Who helps when you are ill?", "Cine ajută dacă ești bolnav?"),
                    doctor, [doctor, baker, bus], 0, "🩺"),
        quiz_choice(lang, f"{e}-l11-03", t(lang, "Wer unterrichtet?", "Qui enseigne ?", "Who teaches?", "Cine predă?"),
                    teacher, [teacher, bike, snow], 0, "👩‍🏫"),
        typed(f"{e}-l11-04", *write_word(lang, baker), [baker], kind="quiz"),
        quiz_choice(lang, f"{e}-l11-05", t(lang, "Hilft die Lehrerin in der Schule?", "L’enseignante aide-t-elle à l’école ?",
                                         "Does the teacher help at school?", "Învățătoarea ajută la școală?"),
                    yes, [yes, no], 0),
    ]
    built[12] = [
        quiz_choice(lang, f"{e}-l12-01", t(lang, "Was ist freundlich?", "Qu’est-ce qui est gentil ?", "What is kind?", "Ce e prietenos?"),
                    share, [share, hit], 0),
        quiz_choice(lang, f"{e}-l12-02", t(lang, "Darf man schlagen?", "A-t-on le droit de frapper ?", "Is hitting allowed?", "Ai voie să lovești?"),
                    no, [yes, no], 1),
        typed(f"{e}-l12-03", *write_word(lang, share), [share], kind="quiz"),
        quiz_choice(lang, f"{e}-l12-04", t(lang, "Warten bis man dran ist?", "Attendre son tour ?", "Wait your turn?", "Aștepți rândul?"),
                    yes, [yes, no], 0),
        quiz_choice(lang, f"{e}-l12-05", t(lang, "Helfen wir einander?", "Est-ce qu’on s’entraide ?", "Do we help each other?", "Ne ajutăm?"),
                    yes, [yes, no], 0),
    ]
    candle = t(lang, "Kerze", "bougie", "candle", "lumânare")
    lamp = t(lang, "Lampe", "lampe", "lamp", "lampă")
    built[13] = [
        quiz_choice(lang, f"{e}-l13-01", t(lang, "Früher Licht?", "Lumière autrefois ?", "Light in the past?", "Lumină odinioară?"),
                    candle, [candle, lamp], 0, "🕯️"),
        quiz_choice(lang, f"{e}-l13-02", t(lang, "Heute Licht?", "Lumière aujourd’hui ?", "Light today?", "Lumină azi?"),
                    lamp, [lamp, candle], 0, "💡"),
        typed(f"{e}-l13-03", *write_word(lang, yesterday), [yesterday], kind="quiz"),
        quiz_choice(lang, f"{e}-l13-04", t(lang, "Pferd oder Auto früher zum Fahren oft?", "Cheval ou voiture autrefois ?",
                                         "Horse or car more often in the past?", "Cal sau mașină mai des în trecut?"),
                    t(lang, "Pferd", "cheval", "horse", "cal"),
                    [t(lang, "Pferd", "cheval", "horse", "cal"), t(lang, "Auto", "voiture", "car", "mașină")], 0, "🐴"),
        quiz_choice(lang, f"{e}-l13-05", t(lang, "Heute oft Auto?", "Aujourd’hui souvent la voiture ?", "Today often a car?", "Azi des mașina?"),
                    yes, [yes, no], 0, "🚗"),
    ]
    built[14] = [
        quiz_choice(lang, f"{e}-l14-01", t(lang, "Welches Fahrzeug?", "Quel véhicule ?", "Which vehicle?", "Ce vehicul?"),
                    bike, [bike, lake, share], 0, "🚲"),
        quiz_choice(lang, f"{e}-l14-02", t(lang, "Welches Fahrzeug?", "Quel véhicule ?", "Which vehicle?", "Ce vehicul?"),
                    bus, [bus, baker, snow], 0, "🚌"),
        quiz_choice(lang, f"{e}-l14-03", t(lang, "Welches Fahrzeug?", "Quel véhicule ?", "Which vehicle?", "Ce vehicul?"),
                    train, [train, park, milk], 0, "🚆"),
        typed(f"{e}-l14-04", *write_word(lang, bus), [bus], kind="quiz", visual="🚌"),
        quiz_choice(lang, f"{e}-l14-05", t(lang, "Helm auf dem Velo?", "Casque à vélo ?", "Helmet on a bike?", "Cască pe bicicletă?"),
                    yes, [yes, no], 0),
    ]
    built[15] = [
        quiz_choice(lang, f"{e}-l15-01", t(lang, "Nachbarland?", "Pays voisin ?", "Neighboring country?", "Țară vecină?"),
                    france, [france, baker, park], 0, "🇫🇷"),
        quiz_choice(lang, f"{e}-l15-02", t(lang, "Ist Deutschland ein Nachbar der Schweiz?", "L’Allemagne est-elle voisine de la Suisse ?",
                                         "Is Germany a neighbor of Switzerland?", "Germania e vecină cu Elveția?"),
                    yes, [yes, no], 0, "🇩🇪"),
        typed(f"{e}-l15-03", *write_word(lang, france), [france], kind="quiz"),
        quiz_choice(lang, f"{e}-l15-04", t(lang, "Italien Nachbar?", "L’Italie est voisine ?", "Italy a neighbor?", "Italia e vecină?"),
                    yes, [yes, no], 0, "🇮🇹"),
        quiz_choice(lang, f"{e}-l15-05", t(lang, "Hallo sagen ist freundlich?", "Dire bonjour est gentil ?", "Saying hello is kind?", "A spune salut e frumos?"),
                    yes, [yes, no], 0),
    ]
    built[16] = [
        quiz_choice(lang, f"{e}-l16-01", t(lang, "Was kommt von der Kuh?", "Qu’est-ce qui vient de la vache ?", "What comes from the cow?", "Ce vine de la vacă?"),
                    milk, [milk, bus, lamp], 0, "🥛"),
        quiz_choice(lang, f"{e}-l16-02", t(lang, "Wo wachsen Äpfel?", "Où poussent les pommes ?", "Where do apples grow?", "Unde cresc merele?"),
                    t(lang, "Baum", "arbre", "tree", "copac"),
                    [t(lang, "Baum", "arbre", "tree", "copac"), train, doctor], 0, "🍎"),
        typed(f"{e}-l16-03", *write_word(lang, milk), [milk], kind="quiz", visual="🥛"),
        quiz_choice(lang, f"{e}-l16-04", t(lang, "Gemüse vom Feld?", "Légumes du champ ?", "Vegetables from the field?", "Legume de pe câmp?"),
                    yes, [yes, no], 0, "🥕"),
        quiz_choice(lang, f"{e}-l16-05", t(lang, "Brot vom Bäcker?", "Pain du boulanger ?", "Bread from the baker?", "Pâine de la brutar?"),
                    yes, [yes, no], 0, "🍞"),
    ]
    trash = t(lang, "Abfall", "déchets", "rubbish", "gunoi")
    built[17] = [
        quiz_choice(lang, f"{e}-l17-01", t(lang, "Was tun mit Papier?", "Que faire du papier ?", "What to do with paper?", "Ce facem cu hârtia?"),
                    recycle, [recycle, hit], 0, "♻️"),
        quiz_choice(lang, f"{e}-l17-02", t(lang, "Müll in den See?", "Déchets dans le lac ?", "Trash in the lake?", "Gunoi în lac?"),
                    no, [yes, no], 1),
        typed(f"{e}-l17-03", *write_word(lang, recycle), [recycle], kind="quiz", visual="♻️"),
        quiz_choice(lang, f"{e}-l17-04", t(lang, "Bäume schützen?", "Protéger les arbres ?", "Protect trees?", "Protejăm copacii?"),
                    yes, [yes, no], 0, "🌳"),
        quiz_choice(lang, f"{e}-l17-05", t(lang, "Wohin mit Abfall?", "Où mettre les déchets ?", "Where does rubbish go?", "Unde merge gunoiul?"),
                    trash, [t(lang, "Tonne", "poubelle", "bin", "pubelă"), lake, milk], 0),
    ]
    built[18] = [
        quiz_choice(lang, f"{e}-l18-01", t(lang, "Was ist nett?", "Qu’est-ce qui est gentil ?", "What is nice?", "Ce e frumos?"),
                    help_w, [help_w, hit], 0),
        quiz_choice(lang, f"{e}-l18-02", t(lang, "Einer Person helfen die etwas trägt?", "Aider quelqu’un qui porte ?",
                                         "Help someone carrying something?", "Ajuți pe cineva care cară?"),
                    yes, [yes, no], 0),
        typed(f"{e}-l18-03", *write_word(lang, help_w), [help_w], kind="quiz"),
        quiz_choice(lang, f"{e}-l18-04", t(lang, "Danke sagen?", "Dire merci ?", "Say thank you?", "Spui mulțumesc?"),
                    yes, [yes, no], 0),
        quiz_choice(lang, f"{e}-l18-05", t(lang, "Teilen im Spiel?", "Partager au jeu ?", "Share in a game?", "Împărțim la joc?"),
                    yes, [yes, no], 0),
    ]
    town = t(lang, "Gemeinde", "commune", "town", "comună")
    built[19] = [
        quiz_choice(lang, f"{e}-l19-01", t(lang, "Meine Gemeinde hat eine Schule?", "Ma commune a une école ?", "My town has a school?", "Comuna mea are o școală?"),
                    yes, [yes, no], 0, "🏫"),
        quiz_choice(lang, f"{e}-l19-02", t(lang, "Gibt es oft einen Brunnen oder Platz?", "Y a-t-il souvent une place ?",
                                         "Is there often a square?", "E adesea o piață?"),
                    yes, [yes, no], 0),
        typed(f"{e}-l19-03", *write_word(lang, town), [town], kind="quiz"),
        quiz_choice(lang, f"{e}-l19-04", place_q, park, [park, france, lamp], 0, "🌳"),
        quiz_choice(lang, f"{e}-l19-05", t(lang, "Bibliothek leiht Bücher?", "La bibliothèque prête des livres ?",
                                         "The library lends books?", "Biblioteca împrumută cărți?"),
                    yes, [yes, no], 0, "📚"),
    ]
    built[20] = [
        quiz_choice(lang, f"{e}-l20-01", flag_q, flag_q, ["🇨🇭", "🇫🇷", "🇩🇪"], 0),
        typed(f"{e}-l20-02", *write_word(lang, share), [share], kind="quiz"),
        quiz_choice(lang, f"{e}-l20-03", t(lang, "Welches Wetter?", "Quel temps ?", "What weather?", "Ce vreme?"), rain, [rain, baker, lamp], 0, "🌧️"),
        quiz_choice(lang, f"{e}-l20-04", t(lang, "Was ist freundlich?", "Qu’est-ce qui est gentil ?", "What is kind?", "Ce e prietenos?"),
                    help_w, [help_w, hit], 0),
        typed(f"{e}-l20-05", *write_word(lang, ch), [ch], kind="quiz", visual="🇨🇭"),
    ]
    return built


def arts_exercises(lang: str) -> dict[int, list[dict]]:
    e = f"{lang}-arts"
    red = t(lang, "rot", "rouge", "red", "roșu")
    blue = t(lang, "blau", "bleu", "blue", "albastru")
    yellow = t(lang, "gelb", "jaune", "yellow", "galben")
    green = t(lang, "grün", "vert", "green", "verde")
    orange = t(lang, "orange", "orange", "orange", "portocaliu")
    purple = t(lang, "violett", "violet", "purple", "violet")
    circle = t(lang, "Kreis", "cercle", "circle", "cerc")
    square = t(lang, "Quadrat", "carré", "square", "pătrat")
    triangle = t(lang, "Dreieck", "triangle", "triangle", "triunghi")
    brush = t(lang, "Pinsel", "pinceau", "brush", "pensulă")
    crayon = t(lang, "Stift", "crayon", "crayon", "creion")
    loud = t(lang, "laut", "fort", "loud", "tare")
    soft = t(lang, "leise", "doux", "soft", "încet")
    drum = t(lang, "Trommel", "tambour", "drum", "tobe")
    piano = t(lang, "Klavier", "piano", "piano", "pian")
    flute = t(lang, "Flöte", "flûte", "flute", "flaut")
    high = t(lang, "hoch", "aigu", "high", "înalt")
    low = t(lang, "tief", "grave", "low", "jos")
    happy = t(lang, "froh", "joyeux", "happy", "vesel")
    sad = t(lang, "traurig", "triste", "sad", "trist")
    paint = t(lang, "malen", "peindre", "paint", "pictez")
    sing = t(lang, "singen", "chanter", "sing", "cânt")
    build = t(lang, "bauen", "construire", "build", "construiesc")
    warm = t(lang, "warm", "chaud", "warm", "cald")
    coldc = t(lang, "kalt", "froid", "cold", "rece")
    dance = t(lang, "Tanz", "danse", "dance", "dans")
    picture = t(lang, "Bild", "image", "picture", "imagine")
    do_note = "do"
    night = t(lang, "Nacht", "nuit", "night", "noapte")
    day = t(lang, "Tag", "jour", "day", "zi")
    yes, no = t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")

    def color_q(n: int, name: str, visual: str, distractors: list[str]) -> dict:
        q = t(lang, "Welche Farbe?", "Quelle couleur ?", "Which color?", "Ce culoare?")
        return quiz_choice(lang, f"{e}-l{n}", q, name, [name, *distractors], 0, visual)

    built = {
        1: [
            color_q("1-01", red, "🟥", [blue, yellow]),
            color_q("1-02", blue, "🟦", [red, yellow]),
            color_q("1-03", yellow, "🟨", [red, blue]),
            typed(f"{e}-l1-04", *write_word(lang, red), [red], kind="quiz", visual="🟥"),
            color_q("1-05", red, "🍅", [blue, green]),
        ],
        2: [
            color_q("2-01", green, "🟩", [red, blue]),
            color_q("2-02", orange, "🟧", [blue, purple]),
            color_q("2-03", purple, "🟪", [yellow, green]),
            typed(f"{e}-l2-04", *write_word(lang, blue), [blue], kind="quiz", visual="🟦"),
            color_q("2-05", green, "🐸", [red, yellow]),
        ],
        3: [
            quiz_choice(lang, f"{e}-l3-01", t(lang, "Welche Form?", "Quelle forme ?", "Which shape?", "Ce formă?"), circle, [circle, square, triangle], 0, "⭕"),
            quiz_choice(lang, f"{e}-l3-02", t(lang, "Welche Form?", "Quelle forme ?", "Which shape?", "Ce formă?"), square, [square, circle, triangle], 0, "⬜"),
            quiz_choice(lang, f"{e}-l3-03", t(lang, "Welche Form?", "Quelle forme ?", "Which shape?", "Ce formă?"), triangle, [triangle, circle, square], 0, "🔺"),
            typed(f"{e}-l3-04", *write_word(lang, circle), [circle], kind="quiz", visual="⭕"),
            quiz_choice(lang, f"{e}-l3-05", t(lang, "Hat ein Kreis Ecken?", "Un cercle a-t-il des coins ?", "Does a circle have corners?", "Cercul are colțuri?"),
                        no, [yes, no], 1),
        ],
        4: [
            quiz_choice(lang, f"{e}-l4-01", t(lang, "Rot plus Gelb?", "Rouge plus jaune ?", "Red plus yellow?", "Roșu plus galben?"),
                        orange, [orange, green, purple], 0),
            quiz_choice(lang, f"{e}-l4-02", t(lang, "Blau plus Gelb?", "Bleu plus jaune ?", "Blue plus yellow?", "Albastru plus galben?"),
                        green, [green, orange, purple], 0),
            quiz_choice(lang, f"{e}-l4-03", t(lang, "Rot plus Blau?", "Rouge plus bleu ?", "Red plus blue?", "Roșu plus albastru?"),
                        purple, [purple, green, orange], 0),
            typed(f"{e}-l4-04", *write_word(lang, green), [green], kind="quiz"),
            quiz_choice(lang, f"{e}-l4-05", t(lang, "Kann man Farben mischen?", "Peut-on mélanger les couleurs ?", "Can we mix colors?", "Putem amesteca culorile?"),
                        yes, [yes, no], 0),
        ],
        5: [
            quiz_choice(lang, f"{e}-l5-01", t(lang, "Womit malen?", "Avec quoi peindre ?", "What do we paint with?", "Cu ce pictăm?"),
                        brush, [brush, drum, bike] if False else [brush, drum, piano], 0, "🖌️"),
            quiz_choice(lang, f"{e}-l5-02", t(lang, "Womit zeichnen?", "Avec quoi dessiner ?", "What do we draw with?", "Cu ce desenăm?"),
                        crayon, [crayon, flute, drum], 0, "🖍️"),
            typed(f"{e}-l5-03", *write_word(lang, brush), [brush], kind="quiz", visual="🖌️"),
            quiz_choice(lang, f"{e}-l5-04", t(lang, "Papier zum Malen?", "Papier pour peindre ?", "Paper for painting?", "Hârtie pentru pictură?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l5-05", t(lang, "Ist eine Schere ein Werkzeug?", "Les ciseaux sont un outil ?", "Are scissors a tool?", "Foarfecele sunt unealtă?"),
                        yes, [yes, no], 0, "✂️"),
        ],
        6: [
            quiz_choice(lang, f"{e}-l6-01", t(lang, "Wie klingt das?", "Comment ça sonne ?", "How does it sound?", "Cum sună?"),
                        loud, [loud, soft], 0, "📢"),
            quiz_choice(lang, f"{e}-l6-02", t(lang, "Wie klingt das?", "Comment ça sonne ?", "How does it sound?", "Cum sună?"),
                        soft, [soft, loud], 0, "🤫"),
            typed(f"{e}-l6-03", *write_word(lang, loud), [loud], kind="quiz"),
            quiz_choice(lang, f"{e}-l6-04", t(lang, "Flüstern ist…", "Chuchoter est…", "Whispering is…", "Șoapta e…"),
                        soft, [soft, loud], 0),
            quiz_choice(lang, f"{e}-l6-05", t(lang, "Trommel oft…", "Le tambour est souvent…", "A drum is often…", "Toba e adesea…"),
                        loud, [loud, soft], 0, "🥁"),
        ],
        7: [
            quiz_choice(lang, f"{e}-l7-01", t(lang, "Welches Instrument?", "Quel instrument ?", "Which instrument?", "Ce instrument?"),
                        drum, [drum, brush, red], 0, "🥁"),
            quiz_choice(lang, f"{e}-l7-02", t(lang, "Welches Instrument?", "Quel instrument ?", "Which instrument?", "Ce instrument?"),
                        piano, [piano, circle, park] if False else [piano, brush, yellow], 0, "🎹"),
            quiz_choice(lang, f"{e}-l7-03", t(lang, "Welches Instrument?", "Quel instrument ?", "Which instrument?", "Ce instrument?"),
                        flute, [flute, square, orange], 0, "🎶"),
            typed(f"{e}-l7-04", *write_word(lang, piano), [piano], kind="quiz", visual="🎹"),
            quiz_choice(lang, f"{e}-l7-05", t(lang, "Kann man zur Musik tanzen?", "Peut-on danser sur la musique ?", "Can we dance to music?", "Putem dansa pe muzică?"),
                        yes, [yes, no], 0),
        ],
        8: [
            quiz_choice(lang, f"{e}-l8-01", t(lang, "Hoher Ton oder tiefer?", "Son aigu ou grave ?", "High or low sound?", "Sunet înalt sau jos?"),
                        high, [high, low], 0, "🐦"),
            quiz_choice(lang, f"{e}-l8-02", t(lang, "Hoher Ton oder tiefer?", "Son aigu ou grave ?", "High or low sound?", "Sunet înalt sau jos?"),
                        low, [low, high], 0, "🐘"),
            typed(f"{e}-l8-03", *write_word(lang, high), [high], kind="quiz"),
            quiz_choice(lang, f"{e}-l8-04", t(lang, "Piep der Vogel oft…", "Le oiseau est souvent…", "A bird is often…", "Pasărea e adesea…"),
                        high, [high, low], 0),
            quiz_choice(lang, f"{e}-l8-05", t(lang, "Grosse Trommel oft…", "Un grand tambour est souvent…", "A big drum is often…", "O tobă mare e adesea…"),
                        low, [low, high], 0),
        ],
        9: [
            quiz_choice(lang, f"{e}-l9-01", t(lang, "Was kommt als Nächstes? 🟥🟦🟥 ?", "Ensuite ? 🟥🟦🟥 ?", "What is next? 🟥🟦🟥 ?", "Ce urmează? 🟥🟦🟥 ?"),
                        "🟦", ["🟦", "🟨", "⬜"], 0),
            quiz_choice(lang, f"{e}-l9-02", t(lang, "Muster: ⭐🌙⭐ ?", "Motif : ⭐🌙⭐ ?", "Pattern: ⭐🌙⭐ ?", "Model: ⭐🌙⭐ ?"),
                        "🌙", ["🌙", "🍎", "🟦"], 0),
            typed(f"{e}-l9-03", t(lang, "Wie oft 🟥 in 🟥🟦🟥?", "Combien de 🟥 dans 🟥🟦🟥 ?", "How many 🟥 in 🟥🟦🟥?", "Câte 🟥 în 🟥🟦🟥?"),
                  type_number_tts(lang),
                  ["2"], keyboard="number", kind="quiz"),
            quiz_choice(lang, f"{e}-l9-04", t(lang, "Wiederholt sich ein Muster?", "Un motif se répète-t-il ?", "Does a pattern repeat?", "Un model se repetă?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l9-05", t(lang, "🔺🔺⬜ als Nächstes wenn 🔺🔺⬜🔺🔺?", "Ensuite si 🔺🔺⬜🔺🔺 ?", "Next if 🔺🔺⬜🔺🔺?", "Urmează dacă 🔺🔺⬜🔺🔺?"),
                        "⬜", ["⬜", "🟦", "⭐"], 0),
        ],
        10: [
            quiz_choice(lang, f"{e}-l10-01", t(lang, "Wie fühlt sich das Bild an?", "Quelle émotion ?", "What feeling?", "Ce emoție?"),
                        happy, [happy, sad], 0, "😊"),
            quiz_choice(lang, f"{e}-l10-02", t(lang, "Wie fühlt sich das Bild an?", "Quelle émotion ?", "What feeling?", "Ce emoție?"),
                        sad, [sad, happy], 0, "😢"),
            typed(f"{e}-l10-03", *write_word(lang, happy), [happy], kind="quiz"),
            quiz_choice(lang, f"{e}-l10-04", t(lang, "Sonne wirkt oft…", "Le soleil paraît souvent…", "The sun often feels…", "Soarele pare adesea…"),
                        happy, [happy, sad], 0, "☀️"),
            quiz_choice(lang, f"{e}-l10-05", t(lang, "Darf Kunst traurig sein?", "L’art peut-il être triste ?", "Can art be sad?", "Arta poate fi tristă?"),
                        yes, [yes, no], 0),
        ],
        11: [
            quiz_choice(lang, f"{e}-l11-01", t(lang, "Was tun wir mit Farbe?", "Que fait-on avec de la peinture ?", "What do we do with paint?", "Ce facem cu vopseaua?"),
                        paint, [paint, sing, build], 0, "🎨"),
            quiz_choice(lang, f"{e}-l11-02", t(lang, "Was tun wir mit der Stimme?", "Que fait-on avec la voix ?", "What do we do with the voice?", "Ce facem cu vocea?"),
                        sing, [sing, paint, build], 0, "🎤"),
            quiz_choice(lang, f"{e}-l11-03", t(lang, "Was tun wir mit Klötzen?", "Que fait-on avec des cubes ?", "What do we do with blocks?", "Ce facem cu cuburile?"),
                        build, [build, sing, paint], 0, "🧱"),
            typed(f"{e}-l11-04", *write_word(lang, sing), [sing], kind="quiz"),
            quiz_choice(lang, f"{e}-l11-05", t(lang, "Gehört Singen zur Kunst?", "Chanter fait-il partie des arts ?", "Is singing part of the arts?", "Cântatul e artă?"),
                        yes, [yes, no], 0),
        ],
        12: [
            quiz_choice(lang, f"{e}-l12-01", t(lang, "Klatsch: 1-2-3, wie viele?", "Claps : 1-2-3, combien ?", "Claps: 1-2-3, how many?", "Aplauze: 1-2-3, câte?"),
                        t(lang, "Wie viele Klatscher hörst du? Es sind drei.",
                          "Combien de claps entends-tu ? Il y en a trois.",
                          "How many claps do you hear? There are three.",
                          "Câte aplauze auzi? Sunt trei."), ["2", "3", "4"], 1),
            typed(f"{e}-l12-02", t(lang, "Wie viele Schläge: ♪♪♪♪ ?", "Combien de temps : ♪♪♪♪ ?", "How many beats: ♪♪♪♪ ?", "Câte bătăi: ♪♪♪♪ ?"),
                  type_number_tts(lang, t(lang, "vier", "quatre", "four", "patru")),
                  ["4"], keyboard="number", kind="quiz"),
            quiz_choice(lang, f"{e}-l12-03", t(lang, "Gleichmässig klatschen ist Rhythmus?", "Frapper régulièrement, c’est le rythme ?",
                                             "Clapping evenly is rhythm?", "Aplaudatul regulat e ritm?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l12-04", t(lang, "Kann man auf ein Lied stampfen?", "Peut-on taper du pied sur une chanson ?",
                                             "Can we stamp to a song?", "Putem bate din picior pe un cântec?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l12-05", *write_word(lang, drum), [drum], kind="quiz", visual="🥁"),
        ],
        13: [
            quiz_choice(lang, f"{e}-l13-01", t(lang, "Ist Rot eine warme Farbe?", "Le rouge est-il chaud ?", "Is red a warm color?", "Roșu e culoare caldă?"),
                        yes, [yes, no], 0, "🟥"),
            quiz_choice(lang, f"{e}-l13-02", t(lang, "Ist Blau eher kalt?", "Le bleu est-il plutôt froid ?", "Is blue rather cold?", "Albastru e mai degrabă rece?"),
                        yes, [yes, no], 0, "🟦"),
            typed(f"{e}-l13-03", *write_word(lang, warm), [warm], kind="quiz"),
            quiz_choice(lang, f"{e}-l13-04", t(lang, "Gelb: warm?", "Jaune : chaud ?", "Yellow: warm?", "Galben: cald?"),
                        yes, [yes, no], 0, "🟨"),
            quiz_choice(lang, f"{e}-l13-05", t(lang, "Eisblau wirkt…", "Le bleu glacier paraît…", "Icy blue feels…", "Albastrul de gheață pare…"),
                        coldc, [coldc, warm], 0),
        ],
        14: [
            quiz_choice(lang, f"{e}-l14-01", t(lang, "Was fühlt sich rau an?", "Qu’est-ce qui est rêche ?", "What feels rough?", "Ce e aspru?"),
                        t(lang, "Rinde", "écorce", "bark", "scoarță"),
                        [t(lang, "Rinde", "écorce", "bark", "scoarță"), t(lang, "Seide", "soie", "silk", "mătase")], 0, "🪵"),
            quiz_choice(lang, f"{e}-l14-02", t(lang, "Was fühlt sich weich an?", "Qu’est-ce qui est doux ?", "What feels soft?", "Ce e moale?"),
                        t(lang, "Wolle", "laine", "wool", "lână"),
                        [t(lang, "Wolle", "laine", "wool", "lână"), t(lang, "Stein", "pierre", "stone", "piatră")], 0, "🧶"),
            typed(f"{e}-l14-03", *write_word(lang, t(lang, "weich", "doux", "soft", "moale")),
                  [t(lang, "weich", "doux", "soft", "moale")], kind="quiz"),
            quiz_choice(lang, f"{e}-l14-04", t(lang, "Kann Kunst verschiedene Texturen haben?", "L’art peut-il avoir des textures ?",
                                             "Can art have textures?", "Arta poate avea texturi?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l14-05", t(lang, "Sandpapier ist rau?", "Le papier de verre est rêche ?", "Is sandpaper rough?", "Șmirghelul e aspru?"),
                        yes, [yes, no], 0),
        ],
        15: [
            quiz_choice(lang, f"{e}-l15-01", t(lang, "Bewegung zur Musik?", "Mouvement sur la musique ?", "Movement to music?", "Mișcare pe muzică?"),
                        dance, [dance, picture], 0, "💃"),
            quiz_choice(lang, f"{e}-l15-02", t(lang, "Etwas zum Anschauen?", "Quelque chose à regarder ?", "Something to look at?", "Ceva de privit?"),
                        picture, [picture, dance], 0, "🖼️"),
            typed(f"{e}-l15-03", *write_word(lang, dance), [dance], kind="quiz"),
            quiz_choice(lang, f"{e}-l15-04", t(lang, "Gehört Tanz zu den Künsten?", "La danse fait-elle partie des arts ?",
                                             "Is dance part of the arts?", "Dansul e artă?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l15-05", t(lang, "Ein Bild hängt an der Wand?", "Une image est au mur ?", "Is a picture on the wall?", "Un tablou e pe perete?"),
                        yes, [yes, no], 0),
        ],
        16: [
            quiz_choice(lang, f"{e}-l16-01", t(lang, "⬛⬜⬛ ?", "⬛⬜⬛ ?", "⬛⬜⬛ ?", "⬛⬜⬛ ?"),
                        "⬜", ["⬜", "🟥", "⭐"], 0),
            quiz_choice(lang, f"{e}-l16-02", t(lang, "ABAB, was ist B wenn A=⭐?", "ABAB, B si A=⭐ ?", "ABAB, what is B if A=⭐?", "ABAB, ce e B dacă A=⭐?"),
                        "🌙", ["🌙", "⭐", "🍎"] if True else [], 0),
            typed(f"{e}-l16-03", t(lang, "Anzahl ⬛ in ⬛⬜⬛⬜", "Nombre de ⬛ dans ⬛⬜⬛⬜", "Count of ⬛ in ⬛⬜⬛⬜", "Câte ⬛ în ⬛⬜⬛⬜"),
                  type_number_tts(lang),
                  ["2"], keyboard="number", kind="quiz"),
            quiz_choice(lang, f"{e}-l16-04", t(lang, "Muster können Farben sein?", "Les motifs peuvent être des couleurs ?",
                                             "Can patterns be colors?", "Modelele pot fi culori?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l16-05", t(lang, "🔴🟢🔴 ?", "🔴🟢🔴 ?", "🔴🟢🔴 ?", "🔴🟢🔴 ?"),
                        "🟢", ["🟢", "🔵", "⭐"], 0),
        ],
        17: [
            quiz_choice(lang, f"{e}-l17-01", t(lang, "Erste Note oft?", "Première note souvent ?", "First note often?", "Prima notă adesea?"),
                        do_note, [do_note, "fa", "si"], 0),
            quiz_choice(lang, f"{e}-l17-02", t(lang, "Do, re, …?", "Do, ré, … ?", "Do, re, …?", "Do, re, …?"),
                        "mi", ["mi", "sol", loud], 0),
            typed(f"{e}-l17-03", *write_word(lang, do_note), [do_note], kind="quiz"),
            quiz_choice(lang, f"{e}-l17-04", t(lang, "Noten helfen zu singen?", "Les notes aident à chanter ?", "Do notes help us sing?", "Notele ajută să cântăm?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l17-05", t(lang, "Re kommt nach do?", "Ré vient après do ?", "Does re come after do?", "Re vine după do?"),
                        yes, [yes, no], 0),
        ],
        18: [
            quiz_choice(lang, f"{e}-l18-01", t(lang, "Sternennacht: Tag oder Nacht?", "Nuit étoilée : jour ou nuit ?", "Starry night: day or night?", "Noapte înstelată: zi sau noapte?"),
                        night, [night, day], 0, "🌌"),
            quiz_choice(lang, f"{e}-l18-02", t(lang, "Sonnenblumen: Tag oder Nacht?", "Tournesols : jour ou nuit ?", "Sunflowers: day or night?", "Floarea-soarelui: zi sau noapte?"),
                        day, [day, night], 0, "🌻"),
            typed(f"{e}-l18-03", *write_word(lang, night), [night], kind="quiz"),
            quiz_choice(lang, f"{e}-l18-04", t(lang, "Kann ein Bild eine Geschichte erzählen?", "Une image raconte-t-elle une histoire ?",
                                             "Can a picture tell a story?", "O imagine spune o poveste?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l18-05", t(lang, "Mond gehört eher zur Nacht?", "La lune va plutôt avec la nuit ?",
                                             "Does the moon belong more to night?", "Luna ține mai mult de noapte?"),
                        yes, [yes, no], 0, "🌙"),
        ],
        19: [
            quiz_choice(lang, f"{e}-l19-01", t(lang, "Schmücken wir eine Karte?", "Décore-t-on une carte ?", "Do we decorate a card?", "Decorăm o felicitare?"),
                        yes, [yes, no], 0, "💌"),
            quiz_choice(lang, f"{e}-l19-02", t(lang, "Mit was kleben?", "Avec quoi coller ?", "What do we glue with?", "Cu ce lipim?"),
                        t(lang, "Leim", "colle", "glue", "lipici"),
                        [t(lang, "Leim", "colle", "glue", "lipici"), drum, night], 0),
            typed(f"{e}-l19-03", *write_word(lang, picture), [picture], kind="quiz"),
            quiz_choice(lang, f"{e}-l19-04", t(lang, "Scherenschnitt ist Gestalten?", "Le découpage est créer ?", "Is cutting paper creating?", "Decupajul e creare?"),
                        yes, [yes, no], 0, "✂️"),
            quiz_choice(lang, f"{e}-l19-05", t(lang, "Dürfen wir Farben wählen?", "Peut-on choisir les couleurs ?", "May we choose colors?", "Putem alege culorile?"),
                        yes, [yes, no], 0),
        ],
        20: [
            color_q("20-01", red, "🟥", [blue, green]),
            typed(f"{e}-l20-02", *write_word(lang, piano), [piano], kind="quiz"),
            quiz_choice(lang, f"{e}-l20-03", t(lang, "Welche Form?", "Quelle forme ?", "Which shape?", "Ce formă?"), circle, [circle, square, triangle], 0, "⭕"),
            quiz_choice(lang, f"{e}-l20-04", t(lang, "Laut oder leise für eine Wiege?", "Fort ou doux pour une berceuse ?",
                                             "Loud or soft for a lullaby?", "Tare sau încet pentru un cântec de leagăn?"),
                        soft, [soft, loud], 0),
            typed(f"{e}-l20-05", *write_word(lang, yellow), [yellow], kind="quiz", visual="🟨"),
        ],
    }
    return built


def corps_exercises(lang: str) -> dict[int, list[dict]]:
    e = f"{lang}-corps"
    head = t(lang, "Kopf", "tête", "head", "cap")
    hand = t(lang, "Hand", "main", "hand", "mână")
    foot = t(lang, "Fuss", "pied", "foot", "picior")
    eye = t(lang, "Auge", "œil", "eye", "ochi")
    ear = t(lang, "Ohr", "oreille", "ear", "ureche")
    run = t(lang, "rennen", "courir", "run", "alerg")
    jump = t(lang, "springen", "sauter", "jump", "sar")
    sit = t(lang, "sitzen", "s’asseoir", "sit", "stau")
    left = t(lang, "links", "gauche", "left", "stânga")
    right = t(lang, "rechts", "droite", "right", "dreapta")
    football = t(lang, "Fussball", "football", "football", "fotbal")
    swim = t(lang, "schwimmen", "nager", "swim", "înot")
    fruit = t(lang, "Frucht", "fruit", "fruit", "fruct")
    candy = t(lang, "Süssigkeit", "bonbon", "sweet", "dulce")
    water = t(lang, "Wasser", "eau", "water", "apă")
    sleep = t(lang, "schlafen", "dormir", "sleep", "dorm")
    wash = t(lang, "waschen", "laver", "wash", "spăl")
    teeth = t(lang, "Zähne", "dents", "teeth", "dinți")
    helmet = t(lang, "Helm", "casque", "helmet", "cască")
    team = t(lang, "Team", "équipe", "team", "echipă")
    stretch = t(lang, "dehnen", "s’étirer", "stretch", "întind")
    heart = t(lang, "Herz", "cœur", "heart", "inimă")
    rest = t(lang, "Pause", "pause", "rest", "pauză")
    fair = t(lang, "fair", "fair-play", "fair", "fair")
    coat = t(lang, "Mantel", "manteau", "coat", "palton")
    balance = t(lang, "Balance", "équilibre", "balance", "echilibru")
    yes, no = t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")

    built = {
        1: [
            quiz_choice(lang, f"{e}-l1-01", t(lang, "Welcher Körperteil?", "Quelle partie du corps ?", "Which body part?", "Ce parte a corpului?"),
                        head, [head, hand, foot], 0, "🙂"),
            quiz_choice(lang, f"{e}-l1-02", t(lang, "Welcher Körperteil?", "Quelle partie du corps ?", "Which body part?", "Ce parte a corpului?"),
                        hand, [hand, head, foot], 0, "✋"),
            quiz_choice(lang, f"{e}-l1-03", t(lang, "Welcher Körperteil?", "Quelle partie du corps ?", "Which body part?", "Ce parte a corpului?"),
                        foot, [foot, head, hand], 0, "🦶"),
            typed(f"{e}-l1-04", *write_word(lang, hand), [hand], kind="quiz", visual="✋"),
            quiz_choice(lang, f"{e}-l1-05", t(lang, "Haben wir zwei Hände?", "Avons-nous deux mains ?", "Do we have two hands?", "Avem două mâini?"),
                        yes, [yes, no], 0),
        ],
        2: [
            quiz_choice(lang, f"{e}-l2-01", t(lang, "Womit sehen wir?", "Avec quoi voyons-nous ?", "What do we see with?", "Cu ce vedem?"),
                        eye, [eye, ear, foot], 0, "👀"),
            quiz_choice(lang, f"{e}-l2-02", t(lang, "Womit hören wir?", "Avec quoi entendons-nous ?", "What do we hear with?", "Cu ce auzim?"),
                        ear, [ear, eye, hand], 0, "👂"),
            typed(f"{e}-l2-03", *write_word(lang, head), [head], kind="quiz"),
            quiz_choice(lang, f"{e}-l2-04", t(lang, "Knie zum Beugen?", "Le genou pour plier ?", "Knee for bending?", "Genunchiul pentru a îndoi?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l2-05", t(lang, "Nase zum Riechen?", "Le nez pour sentir ?", "Nose for smelling?", "Nasul pentru miros?"),
                        yes, [yes, no], 0, "👃"),
        ],
        3: [
            quiz_choice(lang, f"{e}-l3-01", t(lang, "Welche Bewegung?", "Quel mouvement ?", "Which movement?", "Ce mișcare?"),
                        run, [run, sit, sleep], 0, "🏃"),
            quiz_choice(lang, f"{e}-l3-02", t(lang, "Welche Bewegung?", "Quel mouvement ?", "Which movement?", "Ce mișcare?"),
                        jump, [jump, sit, wash], 0, "🤸"),
            quiz_choice(lang, f"{e}-l3-03", t(lang, "Welche Bewegung?", "Quel mouvement ?", "Which movement?", "Ce mișcare?"),
                        sit, [sit, run, swim], 0, "🪑"),
            typed(f"{e}-l3-04", *write_word(lang, run), [run], kind="quiz"),
            quiz_choice(lang, f"{e}-l3-05", t(lang, "Ist Dehnen eine Bewegung?", "S’étirer est un mouvement ?", "Is stretching a movement?", "Întinderea e mișcare?"),
                        yes, [yes, no], 0),
        ],
        4: [
            quiz_choice(lang, f"{e}-l4-01", t(lang, "⬅️ ist?", "⬅️ c’est ?", "⬅️ is?", "⬅️ e?"),
                        left, [left, right], 0),
            quiz_choice(lang, f"{e}-l4-02", t(lang, "➡️ ist?", "➡️ c’est ?", "➡️ is?", "➡️ e?"),
                        right, [right, left], 0),
            typed(f"{e}-l4-03", *write_word(lang, left), [left], kind="quiz"),
            quiz_choice(lang, f"{e}-l4-04", t(lang, "Zwei Hände: links und rechts?", "Deux mains : gauche et droite ?",
                                             "Two hands: left and right?", "Două mâini: stânga și dreapta?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l4-05", *write_word(lang, right), [right], kind="quiz"),
        ],
        5: [
            quiz_choice(lang, f"{e}-l5-01", t(lang, "Welcher Sport?", "Quel sport ?", "Which sport?", "Ce sport?"),
                        football, [football, sleep, candy], 0, "⚽"),
            quiz_choice(lang, f"{e}-l5-02", t(lang, "Welcher Sport?", "Quel sport ?", "Which sport?", "Ce sport?"),
                        swim, [swim, sit, coat], 0, "🏊"),
            typed(f"{e}-l5-03", *write_word(lang, football), [football], kind="quiz", visual="⚽"),
            quiz_choice(lang, f"{e}-l5-04", t(lang, "Kann Sport Spass machen?", "Le sport peut-il être amusant ?", "Can sport be fun?", "Sportul poate fi distractiv?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l5-05", t(lang, "Braucht man zum Schwimmen Wasser?", "Faut-il de l’eau pour nager ?",
                                             "Do you need water to swim?", "Trebuie apă ca să înoți?"),
                        yes, [yes, no], 0),
        ],
        6: [
            quiz_choice(lang, f"{e}-l6-01", t(lang, "Was ist die bessere Pause-Snack-Idee?", "Meilleure idée de goûter ?",
                                             "Better snack idea?", "Idee mai bună de gustare?"),
                        fruit, [fruit, candy], 0, "🍎"),
            quiz_choice(lang, f"{e}-l6-02", t(lang, "Jeden Tag nur Süsses?", "Que des sucreries chaque jour ?", "Only sweets every day?", "Numai dulciuri zilnic?"),
                        no, [yes, no], 1),
            typed(f"{e}-l6-03", *write_word(lang, fruit), [fruit], kind="quiz", visual="🍎"),
            quiz_choice(lang, f"{e}-l6-04", t(lang, "Gemüse ist oft gesund?", "Les légumes sont souvent sains ?", "Are vegetables often healthy?", "Legumele sunt adesea sănătoase?"),
                        yes, [yes, no], 0, "🥕"),
            quiz_choice(lang, f"{e}-l6-05", t(lang, "Apfel ist eine Frucht?", "La pomme est un fruit ?", "Is an apple a fruit?", "Mărul e un fruct?"),
                        yes, [yes, no], 0),
        ],
        7: [
            quiz_choice(lang, f"{e}-l7-01", t(lang, "Was trinken wir oft?", "Que buvons-nous souvent ?", "What do we often drink?", "Ce bem adesea?"),
                        water, [water, candy, coat], 0, "💧"),
            quiz_choice(lang, f"{e}-l7-02", t(lang, "Nach dem Sport trinken?", "Boire après le sport ?", "Drink after sport?", "Bem după sport?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l7-03", *write_word(lang, water), [water], kind="quiz", visual="💧"),
            quiz_choice(lang, f"{e}-l7-04", t(lang, "Hilft Wasser dem Körper?", "L’eau aide-t-elle le corps ?", "Does water help the body?", "Apa ajută corpul?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l7-05", t(lang, "Nur Saft den ganzen Tag?", "Que du jus toute la journée ?", "Only juice all day?", "Numai suc toată ziua?"),
                        no, [yes, no], 1),
        ],
        8: [
            quiz_choice(lang, f"{e}-l8-01", t(lang, "Was braucht der Körper in der Nacht?", "De quoi le corps a-t-il besoin la nuit ?",
                                             "What does the body need at night?", "De ce are nevoie corpul noaptea?"),
                        sleep, [sleep, football, candy], 0, "😴"),
            quiz_choice(lang, f"{e}-l8-02", t(lang, "Müde? Lieber Pause?", "Fatigué ? Une pause ?", "Tired? Better rest?", "Obosit? Mai bine pauză?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l8-03", *write_word(lang, sleep), [sleep], kind="quiz"),
            quiz_choice(lang, f"{e}-l8-04", t(lang, "Schlafen hilft wachsen?", "Dormir aide à grandir ?", "Does sleep help us grow?", "Somnul ajută să creștem?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l8-05", t(lang, "Die ganze Nacht spielen?", "Jouer toute la nuit ?", "Play all night?", "Ne jucăm toată noaptea?"),
                        no, [yes, no], 1),
        ],
        9: [
            quiz_choice(lang, f"{e}-l9-01", t(lang, "Vor dem Essen?", "Avant de manger ?", "Before eating?", "Înainte de masă?"),
                        wash, [wash, jump, candy], 0, "🧼"),
            quiz_choice(lang, f"{e}-l9-02", t(lang, "Nach dem WC Hände waschen?", "Se laver les mains après les toilettes ?",
                                             "Wash hands after the toilet?", "Speli mâinile după toaletă?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l9-03", *write_word(lang, wash), [wash], kind="quiz", visual="🧼"),
            quiz_choice(lang, f"{e}-l9-04", t(lang, "Seife hilft?", "Le savon aide ?", "Does soap help?", "Săpunul ajută?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l9-05", t(lang, "Schmutzige Hände am Apfel?", "Mains sales sur la pomme ?", "Dirty hands on the apple?", "Mâini murdare pe măr?"),
                        no, [yes, no], 1),
        ],
        10: [
            quiz_choice(lang, f"{e}-l10-01", t(lang, "Was putzen wir morgens?", "Que brosse-t-on le matin ?", "What do we brush in the morning?", "Ce periem dimineața?"),
                        teeth, [teeth, football, coat], 0, "🦷"),
            quiz_choice(lang, f"{e}-l10-02", t(lang, "Auch abends Zähne?", "Aussi le soir ?", "Teeth in the evening too?", "Și seara dinții?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l10-03", *write_word(lang, teeth), [teeth], kind="quiz"),
            quiz_choice(lang, f"{e}-l10-04", t(lang, "Zahnbürste benutzen?", "Utiliser une brosse à dents ?", "Use a toothbrush?", "Folosim periuța?"),
                        yes, [yes, no], 0, "🪥"),
            quiz_choice(lang, f"{e}-l10-05", t(lang, "Nur Süsses und nie putzen?", "Que des sucreries et jamais brosser ?",
                                             "Only sweets and never brush?", "Numai dulciuri și niciodată periaj?"),
                        no, [yes, no], 1),
        ],
        11: [
            quiz_choice(lang, f"{e}-l11-01", t(lang, "Auf dem Velo?", "À vélo ?", "On a bike?", "Pe bicicletă?"),
                        helmet, [helmet, candy, sleep], 0, "🪖"),
            quiz_choice(lang, f"{e}-l11-02", t(lang, "Schützt der Helm den Kopf?", "Le casque protège-t-il la tête ?",
                                             "Does a helmet protect the head?", "Casca protejează capul?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l11-03", *write_word(lang, helmet), [helmet], kind="quiz"),
            quiz_choice(lang, f"{e}-l11-04", t(lang, "Ohne Helm rasen?", "Rouler vite sans casque ?", "Race without a helmet?", "Fugi fără cască?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l11-05", t(lang, "Gurt im Auto?", "Ceinture en voiture ?", "Seatbelt in the car?", "Centura în mașină?"),
                        yes, [yes, no], 0),
        ],
        12: [
            quiz_choice(lang, f"{e}-l12-01", t(lang, "Im Wasser: mit wem?", "Dans l’eau : avec qui ?", "In the water: with whom?", "În apă: cu cine?"),
                        t(lang, "einer erwachsenen Person", "un adulte", "an adult", "un adult"),
                        [t(lang, "allein weit draussen", "seul très loin", "alone far out", "singur departe"),
                         t(lang, "einer erwachsenen Person", "un adulte", "an adult", "un adult")], 1),
            quiz_choice(lang, f"{e}-l12-02", t(lang, "Nicht schwimmen können: tiefes Wasser?", "Si on ne sait pas nager : eau profonde ?",
                                             "If you cannot swim: deep water?", "Dacă nu știi să înoți: apă adâncă?"),
                        no, [yes, no], 1),
            typed(f"{e}-l12-03", *write_word(lang, swim), [swim], kind="quiz"),
            quiz_choice(lang, f"{e}-l12-04", t(lang, "Hilfe rufen wenn jemand nicht auftaucht?", "Appeler à l’aide si quelqu’un ne revient pas ?",
                                             "Call for help if someone does not come up?", "Strigi după ajutor dacă cineva nu iese?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l12-05", t(lang, "Schwimmen ist Bewegung?", "Nager est un mouvement ?", "Is swimming movement?", "Înotul e mișcare?"),
                        yes, [yes, no], 0),
        ],
        13: [
            quiz_choice(lang, f"{e}-l13-01", t(lang, "Zusammen spielen?", "Jouer ensemble ?", "Play together?", "Ne jucăm împreună?"),
                        team, [team, candy, coat], 0, "👥"),
            quiz_choice(lang, f"{e}-l13-02", t(lang, "Im Team teilen wir den Ball?", "En équipe on partage le ballon ?",
                                             "On a team we share the ball?", "În echipă împărțim mingea?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l13-03", *write_word(lang, team), [team], kind="quiz"),
            quiz_choice(lang, f"{e}-l13-04", t(lang, "Nur ich, nie passen?", "Seulement moi, jamais de passe ?",
                                             "Only me, never pass?", "Numai eu, niciodată pasă?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l13-05", t(lang, "Klatschen für andere ist nett?", "Applaudir les autres est gentil ?",
                                             "Clapping for others is kind?", "Aplaudăm pe alții e frumos?"),
                        yes, [yes, no], 0),
        ],
        14: [
            quiz_choice(lang, f"{e}-l14-01", t(lang, "Vor dem Sport?", "Avant le sport ?", "Before sport?", "Înainte de sport?"),
                        stretch, [stretch, candy, sleep], 0, "🧘"),
            quiz_choice(lang, f"{e}-l14-02", t(lang, "Aufwärmen schützt?", "L’échauffement protège ?", "Does a warm-up protect?", "Încălzirea protejează?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l14-03", *write_word(lang, stretch), [stretch], kind="quiz"),
            quiz_choice(lang, f"{e}-l14-04", t(lang, "Kalt starten und sprinten ohne Vorbereitung?",
                                             "Partir froid et sprinter sans préparation ?",
                                             "Start cold and sprint with no prep?",
                                             "Pornim reci și sprintăm fără pregătire?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l14-05", t(lang, "Arme kreisen ist Aufwärmen?", "Tourner les bras, c’est s’échauffer ?",
                                             "Arm circles are a warm-up?", "Rotirea brațelor e încălzire?"),
                        yes, [yes, no], 0),
        ],
        15: [
            quiz_choice(lang, f"{e}-l15-01", t(lang, "Was schlägt schneller nach dem Rennen?", "Qu’est-ce qui bat plus vite après une course ?",
                                             "What beats faster after a run?", "Ce bate mai iute după alergare?"),
                        heart, [heart, helmet, fruit], 0, "❤️"),
            quiz_choice(lang, f"{e}-l15-02", t(lang, "Kann man das Herz in der Brust spüren?", "Peut-on sentir le cœur ?",
                                             "Can you feel the heart in the chest?", "Poți simți inima în piept?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l15-03", *write_word(lang, heart), [heart], kind="quiz"),
            quiz_choice(lang, f"{e}-l15-04", t(lang, "In der Pause wird der Puls ruhiger?", "Le pouls se calme à la pause ?",
                                             "Does the pulse calm during rest?", "Pulsul se calmează la pauză?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l15-05", t(lang, "Bewegung kann das Herz stärken?", "Bouger peut fortifier le cœur ?",
                                             "Can movement strengthen the heart?", "Mișcarea poate întări inima?"),
                        yes, [yes, no], 0),
        ],
        16: [
            quiz_choice(lang, f"{e}-l16-01", t(lang, "Nach starker Anstrengung?", "Après un gros effort ?", "After hard effort?", "După efort mare?"),
                        rest, [rest, candy, hit] if False else [rest, candy, football], 0, "😌"),
            quiz_choice(lang, f"{e}-l16-02", t(lang, "Trinken in der Pause?", "Boire pendant la pause ?", "Drink during the break?", "Bem în pauză?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l16-03", *write_word(lang, rest), [rest], kind="quiz"),
            quiz_choice(lang, f"{e}-l16-04", t(lang, "Immer weiter ohne Stopp?", "Toujours continuer sans stop ?", "Always continue with no stop?", "Tot înainte fără stop?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l16-05", t(lang, "Pause gehört zum Sport?", "La pause fait partie du sport ?", "Is rest part of sport?", "Pauza e parte din sport?"),
                        yes, [yes, no], 0),
        ],
        17: [
            quiz_choice(lang, f"{e}-l17-01", t(lang, "Verlieren und die Hand geben?", "Perdre et serrer la main ?", "Lose and shake hands?", "Pierzi și dai mâna?"),
                        fair, [fair, hit] if False else [yes, no], 0),
            quiz_choice(lang, f"{e}-l17-02", t(lang, "Schummeln ist fair?", "Tricher est fair-play ?", "Is cheating fair?", "Trișatul e fair?"),
                        no, [yes, no], 1),
            typed(f"{e}-l17-03", *write_word(lang, fair), [fair], kind="quiz"),
            quiz_choice(lang, f"{e}-l17-04", t(lang, "Anderen gratulieren?", "Féliciter les autres ?", "Congratulate others?", "Felicităm pe alții?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l17-05", t(lang, "Regeln gelten für alle?", "Les règles sont pour tout le monde ?",
                                             "Do rules apply to everyone?", "Regulile sunt pentru toți?"),
                        yes, [yes, no], 0),
        ],
        18: [
            quiz_choice(lang, f"{e}-l18-01", t(lang, "Kalt draussen: was anziehen?", "Dehors il fait froid : que mettre ?",
                                             "Cold outside: what to wear?", "Afară e frig: ce îmbraci?"),
                        coat, [coat, swim, candy], 0, "🧥"),
            quiz_choice(lang, f"{e}-l18-02", t(lang, "Sonne: Mütze oder Kapuze sinnvoll?", "Soleil : un chapeau utile ?",
                                             "Sun: is a hat useful?", "Soare: e utilă o pălărie?"),
                        yes, [yes, no], 0, "🧢"),
            typed(f"{e}-l18-03", *write_word(lang, coat), [coat], kind="quiz"),
            quiz_choice(lang, f"{e}-l18-04", t(lang, "Regen: Jacke?", "Pluie : veste ?", "Rain: jacket?", "Ploaie: geacă?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l18-05", t(lang, "Barfuss im Schnee lange?", "Pieds nus longtemps dans la neige ?",
                                             "Barefoot in the snow for long?", "Desculț în zăpadă mult timp?"),
                        no, [yes, no], 1),
        ],
        19: [
            quiz_choice(lang, f"{e}-l19-01", t(lang, "Auf einem Bein stehen übt…", "Tenir sur un pied exerce…", "Standing on one foot practices…", "Statul pe un picior exersează…"),
                        balance, [balance, candy, sleep], 0, "🦩"),
            quiz_choice(lang, f"{e}-l19-02", t(lang, "Hilft Schauen beim Balancieren?", "Regarder aide-t-il à l’équilibre ?",
                                             "Does looking help with balance?", "Privitul ajută echilibrul?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l19-03", *write_word(lang, balance), [balance], kind="quiz"),
            quiz_choice(lang, f"{e}-l19-04", t(lang, "Weiche Matte zum Üben ok?", "Un tapis moelleux pour s’exercer ?",
                                             "A soft mat for practice is ok?", "Saltea moale pentru exercițiu e ok?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l19-05", t(lang, "Auf einer Mauer ohne Hilfe hoch oben?", "Sur un mur haut sans aide ?",
                                             "On a high wall with no help?", "Pe un zid înalt fără ajutor?"),
                        no, [yes, no], 1),
        ],
        20: [
            quiz_choice(lang, f"{e}-l20-01", t(lang, "Welcher Körperteil?", "Quelle partie du corps ?", "Which body part?", "Ce parte a corpului?"),
                        hand, [hand, coat, candy], 0, "✋"),
            typed(f"{e}-l20-02", *write_word(lang, water), [water], kind="quiz", visual="💧"),
            quiz_choice(lang, f"{e}-l20-03", t(lang, "Auf dem Velo?", "À vélo ?", "On a bike?", "Pe bicicletă?"),
                        helmet, [helmet, candy, sleep], 0),
            quiz_choice(lang, f"{e}-l20-04", t(lang, "Was ist freundlich im Spiel?", "Qu’est-ce qui est gentil au jeu ?",
                                             "What is kind in a game?", "Ce e frumos la joc?"),
                        fair, [yes, no], 0),
            typed(f"{e}-l20-05", *write_word(lang, jump), [jump], kind="quiz"),
        ],
    }
    return built


def numerique_exercises(lang: str) -> dict[int, list[dict]]:
    e = f"{lang}-num"
    computer = t(lang, "Computer", "ordinateur", "computer", "computer")
    tablet = t(lang, "Tablet", "tablette", "tablet", "tabletă")
    phone = t(lang, "Handy", "téléphone", "phone", "telefon")
    mouse = t(lang, "Maus", "souris", "mouse", "mouse")
    keyboard = t(lang, "Tastatur", "clavier", "keyboard", "tastatură")
    screen = t(lang, "Bildschirm", "écran", "screen", "ecran")
    click = t(lang, "klicken", "cliquer", "click", "click")
    typew = t(lang, "tippen", "taper", "type", "scriu")
    icon = t(lang, "Symbol", "icône", "icon", "iconiță")
    folder = t(lang, "Ordner", "dossier", "folder", "dosar")
    filew = t(lang, "Datei", "fichier", "file", "fișier")
    password = t(lang, "Passwort", "mot de passe", "password", "parolă")
    secret = t(lang, "geheim", "secret", "secret", "secret")
    adult = t(lang, "Erwachsene", "adulte", "adult", "adult")
    kind = t(lang, "lieb", "gentil", "kind", "drăguț")
    stranger = t(lang, "fremd", "inconnu", "stranger", "străin")
    pause = t(lang, "Pause", "pause", "break", "pauză")
    first = t(lang, "zuerst", "d’abord", "first", "mai întâi")
    then = t(lang, "dann", "ensuite", "then", "apoi")
    left = t(lang, "links", "gauche", "left", "stânga")
    right = t(lang, "rechts", "droite", "right", "dreapta")
    three = "3"
    power = t(lang, "Strom", "électricité", "electricity", "curent")
    internet = "internet"
    photo = t(lang, "Foto", "photo", "photo", "poză")
    stop = t(lang, "stopp", "stop", "stop", "stop")
    tool = t(lang, "Werkzeug", "outil", "tool", "unealtă")
    toy = t(lang, "Spielzeug", "jouet", "toy", "jucărie")
    yes, no = t(lang, "ja", "oui", "yes", "da"), t(lang, "nein", "non", "no", "nu")

    built = {
        1: [
            quiz_choice(lang, f"{e}-l1-01", t(lang, "Welches Gerät?", "Quel appareil ?", "Which device?", "Ce aparat?"),
                        computer, [computer, toy, fruit] if False else [computer, t(lang, "Ball", "ballon", "ball", "minge"), t(lang, "Banane", "banane", "banana", "banană")], 0, "💻"),
            quiz_choice(lang, f"{e}-l1-02", t(lang, "Welches Gerät?", "Quel appareil ?", "Which device?", "Ce aparat?"),
                        tablet, [tablet, t(lang, "Stift", "crayon", "pencil", "creion"), t(lang, "Schuh", "chaussure", "shoe", "pantof")], 0, "📱"),
            quiz_choice(lang, f"{e}-l1-03", t(lang, "Welches Gerät?", "Quel appareil ?", "Which device?", "Ce aparat?"),
                        phone, [phone, t(lang, "Löffel", "cuillère", "spoon", "lingură"), t(lang, "Buch", "livre", "book", "carte")], 0, "📞"),
            typed(f"{e}-l1-04", *write_word(lang, tablet), [tablet], kind="quiz", visual="📱"),
            quiz_choice(lang, f"{e}-l1-05", t(lang, "Ist ein Computer eine Maschine?", "Un ordinateur est-il une machine ?",
                                             "Is a computer a machine?", "Computerul e o mașină?"),
                        yes, [yes, no], 0),
        ],
        2: [
            quiz_choice(lang, f"{e}-l2-01", t(lang, "Womit zeigt man auf dem Computer?", "Avec quoi montre-t-on sur l’ordinateur ?",
                                             "What do we point with on a computer?", "Cu ce arătăm pe computer?"),
                        mouse, [mouse, password, stranger], 0, "🖱️"),
            quiz_choice(lang, f"{e}-l2-02", t(lang, "Womit schreibt man Buchstaben?", "Avec quoi écrit-on des lettres ?",
                                             "What do we type letters with?", "Cu ce scriem litere?"),
                        keyboard, [keyboard, toy, pause], 0, "⌨️"),
            quiz_choice(lang, f"{e}-l2-03", t(lang, "Wo sieht man das Bild?", "Où voit-on l’image ?", "Where do we see the picture?", "Unde vedem imaginea?"),
                        screen, [screen, mouse, folder], 0, "🖥️"),
            typed(f"{e}-l2-04", *write_word(lang, mouse), [mouse], kind="quiz", visual="🖱️"),
            quiz_choice(lang, f"{e}-l2-05", t(lang, "Hat eine Tastatur Tasten?", "Un clavier a-t-il des touches ?",
                                             "Does a keyboard have keys?", "Tastatura are taste?"),
                        yes, [yes, no], 0),
        ],
        3: [
            quiz_choice(lang, f"{e}-l3-01", t(lang, "Maus-Taste drücken heisst oft…", "Appuyer sur la souris s’appelle souvent…",
                                             "Pressing the mouse is often called…", "Apăsarea mouse-ului se cheamă adesea…"),
                        click, [click, sleep, swim] if False else [click, t(lang, "schlafen", "dormir", "sleep", "dorm"), t(lang, "kochen", "cuisiner", "cook", "gătesc")], 0),
            quiz_choice(lang, f"{e}-l3-02", t(lang, "Buchstaben eingeben heisst…", "Entrer des lettres s’appelle…", "Entering letters is called…", "A introduce litere se cheamă…"),
                        typew, [typew, swim, fruit] if False else [typew, t(lang, "rennen", "courir", "run", "alerg"), t(lang, "malen", "peindre", "paint", "pictez")], 0),
            typed(f"{e}-l3-03", *write_word(lang, click), [click], kind="quiz"),
            quiz_choice(lang, f"{e}-l3-04", t(lang, "Auf einem Tablet tippt man mit dem Finger?", "Sur une tablette on tape avec le doigt ?",
                                             "On a tablet do we tap with a finger?", "Pe tabletă atingem cu degetul?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l3-05", t(lang, "Schreib das Wort: ja", "Écris le mot : oui", "Type the word: yes", "Scrie cuvântul: da"),
                  write_word(lang, yes)[1], [yes], kind="quiz"),
        ],
        4: [
            quiz_choice(lang, f"{e}-l4-01", t(lang, "Ein kleines Bild das ein Programm startet?", "Une petite image qui ouvre un programme ?",
                                             "A small picture that opens a program?", "O imagine mică care deschide un program?"),
                        icon, [icon, stranger, fruit] if False else [icon, t(lang, "Suppe", "soupe", "soup", "supă"), t(lang, "Stein", "pierre", "stone", "piatră")], 0, "🖼️"),
            quiz_choice(lang, f"{e}-l4-02", t(lang, "Ist 🗑️ oft der Papierkorb?", "🗑️ est souvent la corbeille ?", "Is 🗑️ often the trash?", "🗑️ e adesea coșul?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l4-03", *write_word(lang, icon), [icon], kind="quiz"),
            quiz_choice(lang, f"{e}-l4-04", t(lang, "Kann ein Symbol eine Kamera bedeuten?", "Une icône peut-elle être un appareil photo ?",
                                             "Can an icon mean a camera?", "O iconiță poate însemna o cameră?"),
                        yes, [yes, no], 0, "📷"),
            quiz_choice(lang, f"{e}-l4-05", t(lang, "Sind alle Symbole gleich?", "Toutes les icônes sont-elles identiques ?",
                                             "Are all icons the same?", "Toate iconițele sunt la fel?"),
                        no, [yes, no], 1),
        ],
        5: [
            quiz_choice(lang, f"{e}-l5-01", t(lang, "Wo sammeln wir Dateien?", "Où range-t-on les fichiers ?", "Where do we keep files?", "Unde ținem fișierele?"),
                        folder, [folder, stranger, t(lang, "Suppe", "soupe", "soup", "supă")], 0, "📁"),
            quiz_choice(lang, f"{e}-l5-02", t(lang, "Ein einzelnes Dokument ist oft eine…", "Un document est souvent un…",
                                             "A single document is often a…", "Un document e adesea un…"),
                        filew, [filew, adult, pause], 0, "📄"),
            typed(f"{e}-l5-03", *write_word(lang, folder), [folder], kind="quiz", visual="📁"),
            quiz_choice(lang, f"{e}-l5-04", t(lang, "Kann ein Ordner viele Dateien halten?", "Un dossier peut-il contenir beaucoup de fichiers ?",
                                             "Can a folder hold many files?", "Un dosar poate ține multe fișiere?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l5-05", t(lang, "Gehört jede Datei in den Papierkorb?", "Chaque fichier va-t-il à la corbeille ?",
                                             "Does every file belong in the trash?", "Fiecare fișier merge la gunoi?"),
                        no, [yes, no], 1),
        ],
        6: [
            quiz_choice(lang, f"{e}-l6-01", t(lang, "Was hält ein Konto zu?", "Qu’est-ce qui ferme un compte ?",
                                             "What locks an account?", "Ce închide un cont?"),
                        password, [password, toy, photo], 0, "🔐"),
            quiz_choice(lang, f"{e}-l6-02", t(lang, "Ist ein Passwort ein Geheimnis?", "Un mot de passe est-il un secret ?",
                                             "Is a password a secret?", "Parola e un secret?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l6-03", *write_word(lang, password), [password], kind="quiz"),
            quiz_choice(lang, f"{e}-l6-04", t(lang, "Kurzes Passwort wie 1234 ist super sicher?", "1234 est très sûr ?",
                                             "Is 1234 a great password?", "1234 e o parolă grozavă?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l6-05", t(lang, "Ein langes Passwort mit einem Erwachsenen wählen?",
                                             "Choisir un long mot de passe avec un adulte ?",
                                             "Pick a long password with an adult?",
                                             "Alegi o parolă lungă cu un adult?"),
                        yes, [yes, no], 0),
        ],
        7: [
            quiz_choice(lang, f"{e}-l7-01", t(lang, "Darf man das Passwort der ganzen Klasse sagen?",
                                             "Peut-on dire le mot de passe à toute la classe ?",
                                             "May we tell the password to the whole class?",
                                             "Spunem parola întregii clase?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l7-02", t(lang, "Passwort ist…", "Le mot de passe est…", "A password is…", "Parola e…"),
                        secret, [secret, toy, internet], 0),
            typed(f"{e}-l7-03", *write_word(lang, secret), [secret], kind="quiz"),
            quiz_choice(lang, f"{e}-l7-04", t(lang, "Einer vertrauten erwachsenen Person darf man es sagen wenn man Hilfe braucht?",
                                             "Peut-on le dire à un adulte de confiance si on a besoin d’aide ?",
                                             "Can you tell a trusted adult if you need help?",
                                             "Poți spune unui adult de încredere dacă ai nevoie de ajutor?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l7-05", t(lang, "Auf einen Zettel an den Bildschirm kleben?",
                                             "Le coller sur l’écran ?", "Stick it on the screen?", "Îl lipim pe ecran?"),
                        no, [yes, no], 1),
        ],
        8: [
            quiz_choice(lang, f"{e}-l8-01", t(lang, "Wen fragen bei einem komischen Fenster?",
                                             "Qui demander si une fenêtre est bizarre ?",
                                             "Who to ask if a window looks weird?",
                                             "Pe cine întrebi dacă o fereastră e ciudată?"),
                        adult, [adult, stranger, toy], 0, "🧑‍🏫"),
            quiz_choice(lang, f"{e}-l8-02", t(lang, "Etwas herunterladen ohne zu fragen?",
                                             "Télécharger sans demander ?",
                                             "Download without asking?",
                                             "Descarci fără să întrebi?"),
                        no, [yes, no], 1),
            typed(f"{e}-l8-03", *write_word(lang, adult), [adult], kind="quiz"),
            quiz_choice(lang, f"{e}-l8-04", t(lang, "Pop-up: zuerst eine erwachsene Person?",
                                             "Pop-up : d’abord un adulte ?",
                                             "Pop-up: an adult first?",
                                             "Pop-up: mai întâi un adult?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l8-05", t(lang, "Ein Preis gewonnen klicken ohne zu fragen?",
                                             "Cliquer « prix gagné » sans demander ?",
                                             "Click you won a prize without asking?",
                                             "Click ai câștigat un premiu fără să întrebi?"),
                        no, [yes, no], 1),
        ],
        9: [
            quiz_choice(lang, f"{e}-l9-01", t(lang, "Wie sollen Nachrichten sein?", "Comment doivent être les messages ?",
                                             "How should messages be?", "Cum trebuie să fie mesajele?"),
                        kind, [kind, t(lang, "gemein", "méchant", "mean", "rău")], 0, "💬"),
            quiz_choice(lang, f"{e}-l9-02", t(lang, "Gemeine Wörter schicken?", "Envoyer des mots méchants ?",
                                             "Send mean words?", "Trimitem cuvinte urâte?"),
                        no, [yes, no], 1),
            typed(f"{e}-l9-03", *write_word(lang, kind), [kind], kind="quiz"),
            quiz_choice(lang, f"{e}-l9-04", t(lang, "Bitte und Danke auch online?", "S’il te plaît et merci aussi en ligne ?",
                                             "Please and thank you online too?", "Te rog și mulțumesc și online?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l9-05", t(lang, "Ein Foto von jemand anders weiterleiten ohne zu fragen?",
                                             "Transférer la photo de quelqu’un sans demander ?",
                                             "Forward someone else's photo without asking?",
                                             "Trimiți mai departe poza altcuiva fără să întrebi?"),
                        no, [yes, no], 1),
        ],
        10: [
            quiz_choice(lang, f"{e}-l10-01", t(lang, "Jemand Unbekanntes will sich treffen?",
                                             "Quelqu’un d’inconnu veut se rencontrer ?",
                                             "Someone unknown wants to meet?",
                                             "Cineva necunoscut vrea să vă întâlniți?"),
                        t(lang, "eine erwachsene Person fragen", "demander à un adulte", "ask an adult", "întreabă un adult"),
                        [t(lang, "sofort allein gehen", "y aller seul tout de suite", "go alone right away", "mergi singur imediat"),
                         t(lang, "eine erwachsene Person fragen", "demander à un adulte", "ask an adult", "întreabă un adult")], 1),
            quiz_choice(lang, f"{e}-l10-02", t(lang, "Ist jede Person im Netz ein Freund?",
                                             "Chaque personne en ligne est-elle une amie ?",
                                             "Is everyone online a friend?",
                                             "Oricine online e prieten?"),
                        no, [yes, no], 1),
            typed(f"{e}-l10-03", *write_word(lang, stranger), [stranger], kind="quiz"),
            quiz_choice(lang, f"{e}-l10-04", t(lang, "Adresse oder Schule an Unbekannte geben?",
                                             "Donner adresse ou école à un inconnu ?",
                                             "Give address or school to a stranger?",
                                             "Dai adresa sau școala unui străin?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l10-05", t(lang, "Ein unbekannter Mensch ist oft…",
                                             "Une personne inconnue est souvent…",
                                             "An unknown person is often a…",
                                             "O persoană necunoscută e adesea…"),
                        stranger, [stranger, adult, folder], 0),
        ],
        11: [
            quiz_choice(lang, f"{e}-l11-01", t(lang, "Lange nur Bildschirm: was tun?",
                                             "Longtemps uniquement l’écran : que faire ?",
                                             "Only screen for a long time: what to do?",
                                             "Mult timp numai ecran: ce faci?"),
                        pause, [pause, password, stranger], 0, "⏰"),
            quiz_choice(lang, f"{e}-l11-02", t(lang, "Augen-Pause ist sinnvoll?", "Une pause pour les yeux est utile ?",
                                             "Is an eye break useful?", "O pauză pentru ochi e utilă?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l11-03", *write_word(lang, pause), [pause], kind="quiz"),
            quiz_choice(lang, f"{e}-l11-04", t(lang, "Auch draussen spielen?", "Aussi jouer dehors ?", "Also play outside?", "Ne jucăm și afară?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l11-05", t(lang, "Die ganze Nacht am Gerät?", "Toute la nuit sur l’appareil ?",
                                             "All night on the device?", "Toată noaptea pe aparat?"),
                        no, [yes, no], 1),
        ],
        12: [
            quiz_choice(lang, f"{e}-l12-01", t(lang, "Reihenfolge: Schuhe, dann raus. Was kommt zuerst?",
                                             "Ordre : chaussures, puis dehors. Qu’est-ce qui vient d’abord ?",
                                             "Order: shoes, then outside. What comes first?",
                                             "Ordine: pantofi, apoi afară. Ce vine mai întâi?"),
                        first, [first, then], 0),
            quiz_choice(lang, f"{e}-l12-02", t(lang, "Zuerst Hände waschen, ___ essen.",
                                             "D’abord se laver les mains, ___ manger.",
                                             "First wash hands, ___ eat.",
                                             "Mai întâi speli mâinile, ___ mănânci."),
                        then, [then, first], 0),
            typed(f"{e}-l12-03", *write_word(lang, first), [first], kind="quiz"),
            quiz_choice(lang, f"{e}-l12-04", t(lang, "Ein Rezept ist eine Sequenz?", "Une recette est une séquence ?",
                                             "Is a recipe a sequence?", "O rețetă e o secvență?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l12-05", *write_word(lang, then), [then], kind="quiz"),
        ],
        13: [
            quiz_choice(lang, f"{e}-l13-01", t(lang, "Roboter soll nach ⬅️. Wohin?",
                                             "Le robot doit aller ⬅️. Où ?",
                                             "The robot should go ⬅️. Where?",
                                             "Robotul trebuie ⬅️. Încotro?"),
                        left, [left, right], 0),
            quiz_choice(lang, f"{e}-l13-02", t(lang, "Roboter soll nach ➡️. Wohin?",
                                             "Le robot doit aller ➡️. Où ?",
                                             "The robot should go ➡️. Where?",
                                             "Robotul trebuie ➡️. Încotro?"),
                        right, [right, left], 0),
            typed(f"{e}-l13-03", *write_word(lang, left), [left], kind="quiz"),
            quiz_choice(lang, f"{e}-l13-04", t(lang, "Klare Schritte helfen dem Roboter?",
                                             "Des pas clairs aident le robot ?",
                                             "Do clear steps help the robot?",
                                             "Pașii clari ajută robotul?"),
                        yes, [yes, no], 0, "🤖"),
            typed(f"{e}-l13-05", *write_word(lang, right), [right], kind="quiz"),
        ],
        14: [
            quiz_choice(lang, f"{e}-l14-01", t(lang, "Wiederhole dreimal: wie oft?",
                                             "Répète trois fois : combien ?",
                                             "Repeat three times: how often?",
                                             "Repetă de trei ori: de câte ori?"),
                        three, ["2", "3", "5"], 1),
            typed(f"{e}-l14-02", t(lang, "Schreib die Zahl 3", "Écris le nombre 3", "Type the number 3", "Scrie numărul 3"),
                  type_number_tts(lang, t(lang, "drei", "trois", "three", "trei")),
                  ["3"], keyboard="number", kind="quiz"),
            quiz_choice(lang, f"{e}-l14-03", t(lang, "Eine Schleife wiederholt etwas?",
                                             "Une boucle répète-t-elle quelque chose ?",
                                             "Does a loop repeat something?",
                                             "O buclă repetă ceva?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l14-04", t(lang, "Klatsch 3 Mal: 1, 2, …?",
                                             "Tape 3 fois : 1, 2, … ?",
                                             "Clap 3 times: 1, 2, …?",
                                             "Aplaudă de 3 ori: 1, 2, …?"),
                        "3", ["3", "1", "8"], 0),
            quiz_choice(lang, f"{e}-l14-05", t(lang, "Nie wiederholen, immer nur 1 Schritt?",
                                             "Ne jamais répéter, toujours 1 pas ?",
                                             "Never repeat, always only 1 step?",
                                             "Niciodată nu repeți, mereu 1 pas?"),
                        no, [yes, no], 1),
        ],
        15: [
            quiz_choice(lang, f"{e}-l15-01", t(lang, "Wovon lebt ein Computer?",
                                             "De quoi a besoin un ordinateur ?",
                                             "What does a computer need?",
                                             "De ce are nevoie un computer?"),
                        power, [power, toy, photo], 0, "🔌"),
            quiz_choice(lang, f"{e}-l15-02", t(lang, "Ohne Strom bleibt der Bildschirm oft dunkel?",
                                             "Sans électricité l’écran reste souvent noir ?",
                                             "Without power the screen often stays dark?",
                                             "Fără curent ecranul rămâne adesea negru?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l15-03", *write_word(lang, power), [power], kind="quiz"),
            quiz_choice(lang, f"{e}-l15-04", t(lang, "Akku leer: laden?", "Batterie vide : charger ?",
                                             "Empty battery: charge?", "Baterie goală: încărcăm?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l15-05", t(lang, "Gerät ins Wasser legen?", "Mettre l’appareil dans l’eau ?",
                                             "Put the device in water?", "Pui aparatul în apă?"),
                        no, [yes, no], 1),
        ],
        16: [
            quiz_choice(lang, f"{e}-l16-01", t(lang, "Wie heisst das Netz der Seiten?",
                                             "Comment s’appelle le réseau des pages ?",
                                             "What is the network of pages called?",
                                             "Cum se numește rețeaua de pagini?"),
                        internet, [internet, mouse, folder], 0, "🌐"),
            quiz_choice(lang, f"{e}-l16-02", t(lang, "Ist alles im Internet wahr?",
                                             "Tout est-il vrai sur internet ?",
                                             "Is everything on the internet true?",
                                             "Totul pe internet e adevărat?"),
                        no, [yes, no], 1),
            typed(f"{e}-l16-03", *write_word(lang, internet), [internet], kind="quiz"),
            quiz_choice(lang, f"{e}-l16-04", t(lang, "Kann das Internet wie eine Bibliothek sein?",
                                             "Internet peut-il ressembler à une bibliothèque ?",
                                             "Can the internet be like a library?",
                                             "Internetul poate fi ca o bibliotecă?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l16-05", t(lang, "Mit einer erwachsenen Person suchen?",
                                             "Chercher avec un adulte ?",
                                             "Search with an adult?",
                                             "Căutăm cu un adult?"),
                        yes, [yes, no], 0),
        ],
        17: [
            quiz_choice(lang, f"{e}-l17-01", t(lang, "Bevor man ein Foto von jemand teilt?",
                                             "Avant de partager la photo de quelqu’un ?",
                                             "Before sharing someone's photo?",
                                             "Înainte de a trimite poza cuiva?"),
                        t(lang, "fragen", "demander", "ask", "întreabă"),
                        [t(lang, "fragen", "demander", "ask", "întreabă"),
                         t(lang, "einfach senden", "envoyer juste", "just send", "trimiți pur și simplu")], 0, "📷"),
            quiz_choice(lang, f"{e}-l17-02", t(lang, "Darf man jedes Foto ins Netz stellen?",
                                             "Peut-on mettre chaque photo en ligne ?",
                                             "May we put every photo online?",
                                             "Putem pune orice poză online?"),
                        no, [yes, no], 1),
            typed(f"{e}-l17-03", *write_word(lang, photo), [photo], kind="quiz"),
            quiz_choice(lang, f"{e}-l17-04", t(lang, "Ein Kind auf einem Foto: Eltern fragen?",
                                             "Un enfant sur une photo : demander aux parents ?",
                                             "A child in a photo: ask parents?",
                                             "Un copil într-o poză: întrebi părinții?"),
                        yes, [yes, no], 0),
            quiz_choice(lang, f"{e}-l17-05", t(lang, "Standort an alle senden?",
                                             "Envoyer sa position à tout le monde ?",
                                             "Send your location to everyone?",
                                             "Trimiți locația la toată lumea?"),
                        no, [yes, no], 1),
        ],
        18: [
            quiz_choice(lang, f"{e}-l18-01", t(lang, "Wenn einem online mulmig ist?",
                                             "Si on se sent mal en ligne ?",
                                             "If you feel uneasy online?",
                                             "Dacă te simți ciudat online?"),
                        stop, [stop, stranger, toy], 0, "🛑"),
            quiz_choice(lang, f"{e}-l18-02", t(lang, "Gerät weglegen und eine erwachsene Person holen?",
                                             "Poser l’appareil et chercher un adulte ?",
                                             "Put the device down and get an adult?",
                                             "Lași aparatul și iei un adult?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l18-03", *write_word(lang, stop), [stop], kind="quiz"),
            quiz_choice(lang, f"{e}-l18-04", t(lang, "Geheim halten wenn jemand unfreundlich ist?",
                                             "Garder secret si quelqu’un est méchant ?",
                                             "Keep it secret if someone is unkind?",
                                             "Păstrezi secret dacă cineva e urât?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l18-05", t(lang, "Stopp sagen ist erlaubt?",
                                             "A-t-on le droit de dire stop ?",
                                             "Is it ok to say stop?",
                                             "Ai voie să spui stop?"),
                        yes, [yes, no], 0),
        ],
        19: [
            quiz_choice(lang, f"{e}-l19-01", t(lang, "Ein Computer zum Arbeiten ist eher ein…",
                                             "Un ordinateur pour travailler est plutôt un…",
                                             "A computer for work is more a…",
                                             "Un computer pentru muncă e mai degrabă o…"),
                        tool, [tool, toy], 0, "💻"),
            quiz_choice(lang, f"{e}-l19-02", t(lang, "Ein Spiel auf dem Tablet ist eher…",
                                             "Un jeu sur tablette est plutôt…",
                                             "A game on the tablet is more a…",
                                             "Un joc pe tabletă e mai degrabă o…"),
                        toy, [toy, tool], 0, "🎮"),
            typed(f"{e}-l19-03", *write_word(lang, tool), [tool], kind="quiz"),
            quiz_choice(lang, f"{e}-l19-04", t(lang, "Kann dasselbe Gerät Werkzeug und Spiel sein?",
                                             "Le même appareil peut-il être outil et jeu ?",
                                             "Can the same device be a tool and a toy?",
                                             "Același aparat poate fi unealtă și joc?"),
                        yes, [yes, no], 0),
            typed(f"{e}-l19-05", *write_word(lang, toy), [toy], kind="quiz"),
        ],
        20: [
            quiz_choice(lang, f"{e}-l20-01", t(lang, "Welches Gerät?", "Quel appareil ?", "Which device?", "Ce aparat?"),
                        computer, [computer, toy, photo], 0, "💻"),
            typed(f"{e}-l20-02", *write_word(lang, password), [password], kind="quiz"),
            quiz_choice(lang, f"{e}-l20-03", t(lang, "Passwort der Klasse erzählen?",
                                             "Dire le mot de passe à la classe ?",
                                             "Tell the class the password?",
                                             "Spui parolei clasei?"),
                        no, [yes, no], 1),
            quiz_choice(lang, f"{e}-l20-04", t(lang, "Roboter ⬅️ ?", "Robot ⬅️ ?", "Robot ⬅️ ?", "Robot ⬅️ ?"),
                        left, [left, right], 0, "🤖"),
            typed(f"{e}-l20-05", *write_word(lang, stop), [stop], kind="quiz"),
        ],
    }
    return built


BUILDERS = {
    "langues": langues_exercises,
    "math_sciences": math_exercises,
    "shs": shs_exercises,
    "arts": arts_exercises,
    "corps": corps_exercises,
    "numerique": numerique_exercises,
}


def build_pack(domain: str, lang: str) -> dict:
    built = BUILDERS[domain](lang)
    missing = [n for n in range(1, 21) if n not in built or not built[n]]
    if missing:
        raise SystemExit(f"{domain}/{lang} missing levels {missing}")
    for n, items in built.items():
        if len(items) < 4:
            raise SystemExit(f"{domain}/{lang} level {n} has only {len(items)} exercises")
        for item in items:
            if "promptTts" not in item or not item["promptTts"]:
                raise SystemExit(f"{domain}/{lang} level {n} missing promptTts")
            item["promptTts"] = enrich_spoken(lang, item.get("prompt", ""), item["promptTts"])
            item["promptTts"] = strip_spoken_symbols(item["promptTts"]).strip()
            if spoken_word_count(item["promptTts"]) < 4:
                item["promptTts"] = enrich_spoken(lang, item.get("prompt", ""), item["promptTts"])
            spoken = item["promptTts"]
            if spoken_word_count(spoken) < 4:
                raise SystemExit(f"{domain}/{lang} level {n} TTS too short: {spoken!r}")
            if has_spoken_symbols(spoken):
                raise SystemExit(f"{domain}/{lang} level {n} TTS has emoji: {spoken!r}")
            if has_type_listen_wrap(spoken):
                raise SystemExit(f"{domain}/{lang} level {n} TTS wraps a type line: {spoken!r}")
            if has_english_leakage(lang, spoken):
                raise SystemExit(f"{domain}/{lang} level {n} English leakage: {spoken!r}")
    if not any(item.get("answerMode") == "type" for item in built[1]):
        raise SystemExit(f"{domain}/{lang} needs a type exercise in L1")
    return pack_shell(domain, lang, finish_levels(domain, lang, built))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OLD_TOPICS:
        for lang in LANGS:
            path = OUT / f"{old}_{lang}.json"
            if path.exists():
                path.unlink()
                print("removed", path)
    for domain in DOMAINS:
        for lang in LANGS:
            dump(f"{domain}_{lang}.json", build_pack(domain, lang))


if __name__ == "__main__":
    main()
