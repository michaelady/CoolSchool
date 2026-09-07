class I18n {
  const I18n(this.locale);

  final String locale;

  bool get isFr => locale.startsWith('fr');

  String get tagline =>
      isFr ? 'Jouer et apprendre — cycle 1 et 2' : 'Spielen und lernen — Zyklus 1 & 2';

  String get additionSoonNote =>
      isFr ? 'Bientôt là !' : 'Bald da!';

  String get comingSoonHint =>
      isFr ? 'Cette carte arrive bientôt.' : 'Dieses Thema kommt bald.';

  String get subtraction => isFr ? 'Soustraction' : 'Subtraktion';

  String get shapes => isFr ? 'Formes' : 'Formen';

  String get pickLevel => isFr ? 'Choisis un niveau' : 'Wähle ein Level';

  String get lockedHint =>
      isFr ? 'Gagne d’abord une étoile au niveau d’avant.' : 'Schaffe zuerst einen Stern im Level davor.';

  String get speak => isFr ? 'Lire' : 'Vorlesen';

  String get mute => isFr ? 'Son off' : 'Ton aus';

  String get unmute => isFr ? 'Son on' : 'Ton an';

  String get correct => isFr ? 'Bravo !' : 'Richtig!';

  String get wrong => isFr ? 'Presque !' : 'Schade!';

  String get rewardTitle => isFr ? 'Super bien joué !' : 'Super gemacht!';

  String get again => isFr ? 'Encore' : 'Nochmal';

  String get nextLevel => isFr ? 'Niveau suivant' : 'Nächstes Level';

  String get home => isFr ? 'Accueil' : 'Home';

  String get back => isFr ? 'Retour' : 'Zurück';

  String get start => isFr ? 'C’est parti !' : 'Los!';

  String get footer => isFr
      ? 'Pas de compte · Pas de pub · Progrès seulement sur cet appareil'
      : 'Kein Login · Keine Werbung · Fortschritt bleibt auf diesem Gerät';

  String get ageNote => isFr ? 'Pour les enfants jusqu’à 10 ans' : 'Für Kinder bis 10 Jahre';

  String progress(int n, int total) =>
      isFr ? 'Exercice $n sur $total' : 'Aufgabe $n von $total';

  String starsLabel(int stars) =>
      isFr ? '$stars étoile${stars == 1 ? '' : 's'}' : '$stars Stern${stars == 1 ? '' : 'e'}';

  String get deChip => 'DE';

  String get frChip => 'FR';
}
