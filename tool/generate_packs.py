#!/usr/bin/env python3
"""Write CoolSchool JSON content packs (Lehrplan 21, Zyklus 1–2)."""

from __future__ import annotations

import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "content" / "packs"


def dump(name: str, data: dict) -> None:
    path = OUT / name
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(path)


def ex(eid: str, prompt: str, tts: str, choices: list, correct: int, **extra) -> dict:
    row = {
        "id": eid,
        "prompt": prompt,
        "promptTts": tts,
        "choices": [str(c) for c in choices],
        "correctIndex": correct,
    }
    row.update(extra)
    return row


def math_level(lid: str, title: str, subtitle: str, tag: str, unlock: int, items: list[dict]) -> dict:
    return {
        "id": lid,
        "title": title,
        "subtitle": subtitle,
        "lp21Tag": tag,
        "unlockAfterStars": unlock,
        "exercises": items,
    }


# --- Addition (same sums as the original DE/FR packs) ---

ADD_SUMS_L1 = [("1+1", 1, 1, 2, ["1", "2", "3"], 1),
               ("2+3", 2, 3, 5, ["4", "5", "6"], 1),
               ("4+2", 4, 2, 6, ["5", "6", "8"], 1),
               ("5+3", 5, 3, 8, ["7", "8", "9"], 1),
               ("6+4", 6, 4, 10, ["9", "10", "11"], 1),
               ("7+2", 7, 2, 9, ["8", "9", "10"], 1)]
ADD_SUMS_L2 = [("10+4", 10, 4, 14, ["13", "14", "16"], 1),
               ("8+5", 8, 5, 13, ["12", "13", "15"], 1),
               ("7+7", 7, 7, 14, ["12", "14", "16"], 1),
               ("11+3", 11, 3, 14, ["13", "14", "15"], 1),
               ("9+6", 9, 6, 15, ["14", "15", "16"], 1),
               ("12+8", 12, 8, 20, ["18", "19", "20"], 2)]
ADD_SUMS_L3 = [("9+2", 9, 2, 11, ["10", "11", "12"], 1),
               ("8+7", 8, 7, 15, ["14", "15", "16"], 1),
               ("6+5", 6, 5, 11, ["10", "11", "12"], 1),
               ("9+8", 9, 8, 17, ["16", "17", "18"], 1),
               ("7+6", 7, 6, 13, ["12", "13", "14"], 1),
               ("5+8", 5, 8, 13, ["12", "13", "14"], 1)]

NUM = {
    "de": {1: "eins", 2: "zwei", 3: "drei", 4: "vier", 5: "fünf", 6: "sechs", 7: "sieben",
           8: "acht", 9: "neun", 10: "zehn", 11: "elf", 12: "zwölf", 13: "dreizehn",
           14: "vierzehn", 15: "fünfzehn", 16: "sechzehn", 17: "siebzehn", 18: "achtzehn",
           19: "neunzehn", 20: "zwanzig"},
    "fr": {1: "un", 2: "deux", 3: "trois", 4: "quatre", 5: "cinq", 6: "six", 7: "sept",
           8: "huit", 9: "neuf", 10: "dix", 11: "onze", 12: "douze", 13: "treize",
           14: "quatorze", 15: "quinze", 16: "seize", 17: "dix-sept", 18: "dix-huit",
           19: "dix-neuf", 20: "vingt"},
    "en": {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven",
           8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve", 13: "thirteen",
           14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen", 18: "eighteen",
           19: "nineteen", 20: "twenty"},
    "ro": {1: "unu", 2: "doi", 3: "trei", 4: "patru", 5: "cinci", 6: "șase", 7: "șapte",
           8: "opt", 9: "nouă", 10: "zece", 11: "unsprezece", 12: "doisprezece",
           13: "treisprezece", 14: "paisprezece", 15: "cincisprezece", 16: "șaisprezece",
           17: "șaptesprezece", 18: "optsprezece", 19: "nouăsprezece", 20: "douăzeci"},
}


def nword(lang: str, value: int) -> str:
    return NUM[lang][value]


def add_tts(lang: str, a: int, b: int) -> str:
    left, right = nword(lang, a), nword(lang, b)
    return {
        "de": f"Was ist {left} plus {right}?",
        "fr": f"Combien font {left} plus {right} ?",
        "en": f"What is {left} plus {right}?",
        "ro": f"Cât fac {left} plus {right}?",
    }[lang]


def sub_tts(lang: str, a: int, b: int) -> str:
    left, right = nword(lang, a), nword(lang, b)
    minus = {"de": "minus", "fr": "moins", "en": "minus", "ro": "scăzut"}[lang]
    return {
        "de": f"Was ist {left} {minus} {right}?",
        "fr": f"Combien font {left} {minus} {right} ?",
        "en": f"What is {left} {minus} {right}?",
        "ro": f"Cât fac {left} {minus} {right}?",
    }[lang]


ADD_META = {
    "de": {
        "title": "Addition", "subtitle": "Plusrechnen",
        "label": "Zahl und Variable", "focus": "Operieren und benennen", "cycle": "Zyklus 1–2",
        "l1": ("Zahlenfreunde", "Plus bis 10", "MA.1.A · Zahlenraum 10"),
        "l2": ("Zwanzigerraum", "Plus bis 20", "MA.1.B · Zahlenraum 20"),
        "l3": ("Zehnerübergang", "Über die 10", "MA.1.B · Zehnerübergang"),
    },
    "fr": {
        "title": "Addition", "subtitle": "Calculer plus",
        "label": "Nombre et variable", "focus": "Opérer et nommer", "cycle": "Cycle 1–2",
        "l1": ("Amis des nombres", "Plus jusqu’à 10", "MA.1.A · Espace 10"),
        "l2": ("Jusqu’à vingt", "Plus jusqu’à 20", "MA.1.B · Espace 20"),
        "l3": ("Passer la dizaine", "Au-delà de 10", "MA.1.B · Passage de 10"),
    },
    "en": {
        "title": "Addition", "subtitle": "Adding numbers",
        "label": "Number and variables", "focus": "Operating and naming", "cycle": "Cycle 1–2",
        "l1": ("Number friends", "Plus to 10", "MA.1.A · Number range 10"),
        "l2": ("Up to twenty", "Plus to 20", "MA.1.B · Number range 20"),
        "l3": ("Crossing ten", "Over the 10", "MA.1.B · Crossing ten"),
    },
    "ro": {
        "title": "Adunare", "subtitle": "Adunăm numere",
        "label": "Număr și variabilă", "focus": "Operare și denumire", "cycle": "Ciclul 1–2",
        "l1": ("Prietenii numerelor", "Plus până la 10", "MA.1.A · Spațiul 10"),
        "l2": ("Până la douăzeci", "Plus până la 20", "MA.1.B · Spațiul 20"),
        "l3": ("Trecem de 10", "Peste 10", "MA.1.B · Trecerea zecii"),
    },
}


def addition_pack(lang: str) -> dict:
    meta = ADD_META[lang]
    levels = []
    for idx, (lid, sums, unlock) in enumerate([
        ("addition-l1", ADD_SUMS_L1, 0),
        ("addition-l2", ADD_SUMS_L2, 1),
        ("addition-l3", ADD_SUMS_L3, 1),
    ], start=1):
        title, subtitle, tag = meta[f"l{idx}"]
        exercises = []
        for i, (key, a, b, _s, choices, correct) in enumerate(sums, start=1):
            exercises.append(ex(
                f"{lang}-add-l{idx}-{i:02d}",
                f"{a} + {b} = ?",
                add_tts(lang, a, b),
                choices,
                correct,
            ))
        levels.append(math_level(lid, title, subtitle, tag, unlock, exercises))
    return {
        "id": "addition",
        "locale": lang,
        "emoji": "➕",
        "color": "#FF8A5B",
        "title": meta["title"],
        "subtitle": meta["subtitle"],
        "lp21": {
            "competenceId": "MA.1",
            "label": meta["label"],
            "focusId": "MA.1.B",
            "focusLabel": meta["focus"],
            "cycle": meta["cycle"],
        },
        "levels": levels,
    }


SUB_L1 = [(5, 2, ["2", "3", "4"], 1), (6, 1, ["4", "5", "6"], 1), (8, 3, ["4", "5", "6"], 1),
          (9, 4, ["4", "5", "6"], 1), (7, 5, ["2", "3", "4"], 0), (4, 2, ["1", "2", "3"], 1)]
SUB_L2 = [(12, 4, ["7", "8", "9"], 1), (15, 6, ["8", "9", "10"], 1), (11, 3, ["7", "8", "9"], 1),
          (14, 5, ["8", "9", "10"], 1), (18, 9, ["8", "9", "10"], 1), (16, 7, ["8", "9", "10"], 1)]

SUB_META = {
    "de": {
        "title": "Subtraktion", "subtitle": "Minusrechnen",
        "label": "Zahl und Variable", "focus": "Operieren und benennen", "cycle": "Zyklus 1–2",
        "l1": ("Wegnehmen", "Minus bis 10", "MA.1.A · Zahlenraum 10"),
        "l2": ("Zurückzählen", "Minus bis 20", "MA.1.B · Zahlenraum 20"),
    },
    "fr": {
        "title": "Soustraction", "subtitle": "Calculer moins",
        "label": "Nombre et variable", "focus": "Opérer et nommer", "cycle": "Cycle 1–2",
        "l1": ("Enlever", "Moins jusqu’à 10", "MA.1.A · Espace 10"),
        "l2": ("Compter à rebours", "Moins jusqu’à 20", "MA.1.B · Espace 20"),
    },
    "en": {
        "title": "Subtraction", "subtitle": "Taking away",
        "label": "Number and variables", "focus": "Operating and naming", "cycle": "Cycle 1–2",
        "l1": ("Take away", "Minus to 10", "MA.1.A · Number range 10"),
        "l2": ("Count back", "Minus to 20", "MA.1.B · Number range 20"),
    },
    "ro": {
        "title": "Scădere", "subtitle": "Scădem numere",
        "label": "Număr și variabilă", "focus": "Operare și denumire", "cycle": "Ciclul 1–2",
        "l1": ("Luăm", "Minus până la 10", "MA.1.A · Spațiul 10"),
        "l2": ("Numărăm înapoi", "Minus până la 20", "MA.1.B · Spațiul 20"),
    },
}


def subtraction_pack(lang: str) -> dict:
    meta = SUB_META[lang]
    levels = []
    for idx, (lid, sums, unlock) in enumerate([
        ("subtraction-l1", SUB_L1, 0),
        ("subtraction-l2", SUB_L2, 1),
    ], start=1):
        title, subtitle, tag = meta[f"l{idx}"]
        exercises = []
        for i, (a, b, choices, correct) in enumerate(sums, start=1):
            exercises.append(ex(
                f"{lang}-sub-l{idx}-{i:02d}",
                f"{a} − {b} = ?",
                sub_tts(lang, a, b),
                choices,
                correct,
            ))
        levels.append(math_level(lid, title, subtitle, tag, unlock, exercises))
    return {
        "id": "subtraction",
        "locale": lang,
        "emoji": "➖",
        "color": "#A78BFA",
        "title": meta["title"],
        "subtitle": meta["subtitle"],
        "lp21": {
            "competenceId": "MA.1",
            "label": meta["label"],
            "focusId": "MA.1.B",
            "focusLabel": meta["focus"],
            "cycle": meta["cycle"],
        },
        "levels": levels,
    }


COUNT_L1 = [
    (["🍎"] * 3, "2", "3", "4", 1, "apple"),
    (["⭐"] * 2, "1", "2", "4", 1, "star"),
    (["🌼"] * 5, "4", "5", "6", 1, "flower"),
    (["🔵"] * 4, "3", "4", "5", 1, "dot"),
    (["🐸"] * 1, "1", "2", "3", 0, "frog"),
    (["🐠"] * 3, "2", "3", "5", 1, "fish"),
]
COUNT_L2 = [
    (["🍎"] * 7, "6", "7", "8", 1, "apple"),
    (["⭐"] * 6, "5", "6", "8", 1, "star"),
    (["🌼"] * 9, "8", "9", "10", 1, "flower"),
    (["🔵"] * 8, "7", "8", "9", 1, "dot"),
    (["🐸"] * 10, "8", "9", "10", 2, "frog"),
    (["🐠"] * 6, "5", "6", "7", 1, "fish"),
]

COUNT_WORDS = {
    "de": {"apple": "Äpfel", "star": "Sterne", "flower": "Blumen", "dot": "Punkte",
           "frog": "Frösche", "fish": "Fische", "how": "Wie viele?",
           "tts": "Wie viele {noun} siehst du?"},
    "fr": {"apple": "pommes", "star": "étoiles", "flower": "fleurs", "dot": "points",
           "frog": "grenouilles", "fish": "poissons", "how": "Combien ?",
           "tts": "Combien de {noun} vois-tu ?"},
    "en": {"apple": "apples", "star": "stars", "flower": "flowers", "dot": "dots",
           "frog": "frogs", "fish": "fish", "how": "How many?",
           "tts": "How many {noun} do you see?"},
    "ro": {"apple": "mere", "star": "stele", "flower": "flori", "dot": "puncte",
           "frog": "broaște", "fish": "pești", "how": "Câte sunt?",
           "tts": "Câte {noun} vezi?"},
}

COUNT_META = {
    "de": {
        "title": "Zählen", "subtitle": "Wie viele?",
        "label": "Zahl und Variable", "focus": "Zahlen aufbauen", "cycle": "Zyklus 1",
        "l1": ("Kleine Mengen", "Zähle bis 5", "MA.1.A · Anzahlen"),
        "l2": ("Mehr Dinge", "Zähle bis 10", "MA.1.A · Zahlenraum 10"),
    },
    "fr": {
        "title": "Compter", "subtitle": "Combien y en a-t-il ?",
        "label": "Nombre et variable", "focus": "Construire les nombres", "cycle": "Cycle 1",
        "l1": ("Petites quantités", "Compter jusqu’à 5", "MA.1.A · Quantités"),
        "l2": ("Plus d’objets", "Compter jusqu’à 10", "MA.1.A · Espace 10"),
    },
    "en": {
        "title": "Counting", "subtitle": "How many?",
        "label": "Number and variables", "focus": "Building numbers", "cycle": "Cycle 1",
        "l1": ("Small groups", "Count to 5", "MA.1.A · Quantities"),
        "l2": ("More things", "Count to 10", "MA.1.A · Number range 10"),
    },
    "ro": {
        "title": "Numărare", "subtitle": "Câte sunt?",
        "label": "Număr și variabilă", "focus": "Construirea numerelor", "cycle": "Ciclul 1",
        "l1": ("Grupuri mici", "Numără până la 5", "MA.1.A · Cantități"),
        "l2": ("Mai multe lucruri", "Numără până la 10", "MA.1.A · Spațiul 10"),
    },
}


def counting_pack(lang: str) -> dict:
    meta = COUNT_META[lang]
    words = COUNT_WORDS[lang]
    levels = []
    for idx, (lid, rows, unlock) in enumerate([
        ("counting-l1", COUNT_L1, 0),
        ("counting-l2", COUNT_L2, 1),
    ], start=1):
        title, subtitle, tag = meta[f"l{idx}"]
        exercises = []
        for i, (items, a, b, c, correct, noun) in enumerate(rows, start=1):
            exercises.append(ex(
                f"{lang}-cnt-l{idx}-{i:02d}",
                words["how"],
                words["tts"].format(noun=words[noun]),
                [a, b, c],
                correct,
                kind="counting",
                items=items,
            ))
        levels.append(math_level(lid, title, subtitle, tag, unlock, exercises))
    return {
        "id": "counting",
        "locale": lang,
        "emoji": "🔢",
        "color": "#2FA84A",
        "title": meta["title"],
        "subtitle": meta["subtitle"],
        "lp21": {
            "competenceId": "MA.1",
            "label": meta["label"],
            "focusId": "MA.1.A",
            "focusLabel": meta["focus"],
            "cycle": meta["cycle"],
        },
        "levels": levels,
    }


# word, emoji, distractors
VOCAB_WORDS = [
    ("book", "📚", ["✏️", "🏫"]),
    ("pencil", "✏️", ["📚", "🍎"]),
    ("school", "🏫", ["🏠", "🌳"]),
    ("apple", "🍎", ["🌸", "⭐"]),
    ("sun", "☀️", ["⭐", "🌸"]),
    ("cat", "🐱", ["🐕", "🐸"]),
]
VOCAB_LISTEN = [
    ("dog", "🐕", ["🐱", "🐸"]),
    ("tree", "🌳", ["🏠", "🌸"]),
    ("house", "🏠", ["🏫", "🌳"]),
    ("bag", "🎒", ["📚", "✏️"]),
    ("star", "⭐", ["☀️", "🌼"]),
    ("flower", "🌸", ["🍎", "🌳"]),
]

VOCAB_LEX = {
    "de": {
        "book": "Buch", "pencil": "Stift", "school": "Schule", "apple": "Apfel",
        "sun": "Sonne", "cat": "Katze", "dog": "Hund", "tree": "Baum",
        "house": "Haus", "bag": "Tasche", "star": "Stern", "flower": "Blume",
        "match": "Tippe das Bild", "listen": "Hör zu und tippe",
        "tts_match": "{word}", "tts_listen": "{word}",
    },
    "fr": {
        "book": "livre", "pencil": "crayon", "school": "école", "apple": "pomme",
        "sun": "soleil", "cat": "chat", "dog": "chien", "tree": "arbre",
        "house": "maison", "bag": "sac", "star": "étoile", "flower": "fleur",
        "match": "Touche l’image", "listen": "Écoute et touche",
        "tts_match": "{word}", "tts_listen": "{word}",
    },
    "en": {
        "book": "book", "pencil": "pencil", "school": "school", "apple": "apple",
        "sun": "sun", "cat": "cat", "dog": "dog", "tree": "tree",
        "house": "house", "bag": "bag", "star": "star", "flower": "flower",
        "match": "Tap the picture", "listen": "Listen and tap",
        "tts_match": "{word}", "tts_listen": "{word}",
    },
    "ro": {
        "book": "carte", "pencil": "creion", "school": "școală", "apple": "măr",
        "sun": "soare", "cat": "pisică", "dog": "câine", "tree": "copac",
        "house": "casă", "bag": "ghiozdan", "star": "stea", "flower": "floare",
        "match": "Atinge imaginea", "listen": "Ascultă și atinge",
        "tts_match": "{word}", "tts_listen": "{word}",
    },
}

VOCAB_META = {
    "de": {
        "title": "Schulsprache", "subtitle": "Wörter und Bilder",
        "label": "Hören", "focus": "Wortschatz", "cycle": "Zyklus 1",
        "l1": ("Wort und Bild", "Was passt?", "D.1.A · Wortschatz"),
        "l2": ("Hör zu", "Höre und tippe", "D.1.B · Hören"),
    },
    "fr": {
        "title": "Langue de l’école", "subtitle": "Mots et images",
        "label": "Écouter", "focus": "Vocabulaire", "cycle": "Cycle 1",
        "l1": ("Mot et image", "Qu’est-ce qui va ?", "L1.1.A · Vocabulaire"),
        "l2": ("Écoute", "Écoute et touche", "L1.1.B · Écouter"),
    },
    "en": {
        "title": "School words", "subtitle": "Words and pictures",
        "label": "Listening", "focus": "Vocabulary", "cycle": "Cycle 1",
        "l1": ("Word and picture", "What matches?", "L1.1.A · Vocabulary"),
        "l2": ("Listen", "Listen and tap", "L1.1.B · Listening"),
    },
    "ro": {
        "title": "Cuvinte de școală", "subtitle": "Cuvinte și imagini",
        "label": "Ascultare", "focus": "Vocabular", "cycle": "Ciclul 1",
        "l1": ("Cuvânt și imagine", "Ce se potrivește?", "L1.1.A · Vocabular"),
        "l2": ("Ascultă", "Ascultă și atinge", "L1.1.B · Ascultare"),
    },
}


def vocab_pack(lang: str) -> dict:
    meta = VOCAB_META[lang]
    lex = VOCAB_LEX[lang]
    levels = []
    for idx, (lid, rows, unlock, listen) in enumerate([
        ("vocab-l1", VOCAB_WORDS, 0, False),
        ("vocab-l2", VOCAB_LISTEN, 1, True),
    ], start=1):
        title, subtitle, tag = meta[f"l{idx}"]
        exercises = []
        for i, (key, emoji, distractors) in enumerate(rows, start=1):
            word = lex[key]
            pictures = [emoji, *distractors]
            correct = (i - 1) % len(pictures)
            pictures[0], pictures[correct] = pictures[correct], pictures[0]
            tts = (lex["tts_listen"] if listen else lex["tts_match"]).format(word=word)
            exercises.append(ex(
                f"{lang}-voc-l{idx}-{i:02d}",
                lex["listen"] if listen else word,
                tts,
                pictures,
                correct,
                kind="vocab",
            ))
        levels.append(math_level(lid, title, subtitle, tag, unlock, exercises))
    return {
        "id": "vocab",
        "locale": lang,
        "emoji": "🗣️",
        "color": "#4CC9F0",
        "title": meta["title"],
        "subtitle": meta["subtitle"],
        "lp21": {
            "competenceId": "D.1" if lang == "de" else "L1.1",
            "label": meta["label"],
            "focusId": "D.1.A" if lang == "de" else "L1.1.A",
            "focusLabel": meta["focus"],
            "cycle": meta["cycle"],
        },
        "levels": levels,
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for lang in ("de", "fr", "en", "ro"):
        # Keep hand-authored DE/FR addition; still rewrite EN/RO and refresh all new topics.
        if lang in {"en", "ro"}:
            dump(f"addition_{lang}.json", addition_pack(lang))
        dump(f"subtraction_{lang}.json", subtraction_pack(lang))
        dump(f"counting_{lang}.json", counting_pack(lang))
        dump(f"vocab_{lang}.json", vocab_pack(lang))


if __name__ == "__main__":
    main()
