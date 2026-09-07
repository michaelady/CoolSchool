import 'app_locales.dart';

class I18n {
  const I18n(this.locale);

  final String locale;

  String get lang => AppLocales.normalize(locale);

  bool get isFr => lang == 'fr';
  bool get isEn => lang == 'en';
  bool get isRo => lang == 'ro';

  String get tagline => switch (lang) {
        'fr' => 'Jouer et apprendre — cycle 1 et 2',
        'en' => 'Play and learn — cycle 1 and 2',
        'ro' => 'Joacă și învață — ciclul 1 și 2',
        _ => 'Spielen und lernen — Zyklus 1 & 2',
      };

  String get comingSoonHint => switch (lang) {
        'fr' => 'Cette carte arrive bientôt.',
        'en' => 'This topic is coming soon.',
        'ro' => 'Această temă vine în curând.',
        _ => 'Dieses Thema kommt bald.',
      };

  String get subtraction => switch (lang) {
        'fr' => 'Soustraction',
        'en' => 'Subtraction',
        'ro' => 'Scădere',
        _ => 'Subtraktion',
      };

  String get counting => switch (lang) {
        'fr' => 'Compter',
        'en' => 'Counting',
        'ro' => 'Numărare',
        _ => 'Zählen',
      };

  String get vocab => switch (lang) {
        'fr' => 'Langue de l’école',
        'en' => 'School words',
        'ro' => 'Cuvinte de școală',
        _ => 'Schulsprache',
      };

  String get pickLevel => switch (lang) {
        'fr' => 'Choisis un niveau',
        'en' => 'Pick a level',
        'ro' => 'Alege un nivel',
        _ => 'Wähle ein Level',
      };

  String get lockedHint => switch (lang) {
        'fr' => 'Gagne d’abord une étoile au niveau d’avant.',
        'en' => 'Earn a star on the previous level first.',
        'ro' => 'Câștigă mai întâi o stea la nivelul anterior.',
        _ => 'Schaffe zuerst einen Stern im Level davor.',
      };

  String get speak => switch (lang) {
        'fr' => 'Lire',
        'en' => 'Read aloud',
        'ro' => 'Citește',
        _ => 'Vorlesen',
      };

  String get mute => switch (lang) {
        'fr' => 'Son off',
        'en' => 'Sound off',
        'ro' => 'Sunet oprit',
        _ => 'Ton aus',
      };

  String get unmute => switch (lang) {
        'fr' => 'Son on',
        'en' => 'Sound on',
        'ro' => 'Sunet pornit',
        _ => 'Ton an',
      };

  String get correct => switch (lang) {
        'fr' => 'Bravo !',
        'en' => 'Right!',
        'ro' => 'Corect!',
        _ => 'Richtig!',
      };

  String get wrong => switch (lang) {
        'fr' => 'Presque !',
        'en' => 'Almost!',
        'ro' => 'Aproape!',
        _ => 'Schade!',
      };

  String get rewardTitle => switch (lang) {
        'fr' => 'Super bien joué !',
        'en' => 'Super job!',
        'ro' => 'Super! Bravo!',
        _ => 'Super gemacht!',
      };

  String get again => switch (lang) {
        'fr' => 'Encore',
        'en' => 'Again',
        'ro' => 'Din nou',
        _ => 'Nochmal',
      };

  String get nextLevel => switch (lang) {
        'fr' => 'Niveau suivant',
        'en' => 'Next level',
        'ro' => 'Nivelul următor',
        _ => 'Nächstes Level',
      };

  String get home => switch (lang) {
        'fr' => 'Accueil',
        'en' => 'Home',
        'ro' => 'Acasă',
        _ => 'Home',
      };

  String get back => switch (lang) {
        'fr' => 'Retour',
        'en' => 'Back',
        'ro' => 'Înapoi',
        _ => 'Zurück',
      };

  String get footer => switch (lang) {
        'fr' => 'Pas de compte · Pas de pub · Progrès seulement sur cet appareil',
        'en' => 'No account · No ads · Progress stays on this device',
        'ro' => 'Fără cont · Fără reclame · Progresul rămâne pe acest dispozitiv',
        _ => 'Kein Login · Keine Werbung · Fortschritt bleibt auf diesem Gerät',
      };

  String get ageNote => switch (lang) {
        'fr' => 'Pour les enfants jusqu’à 10 ans',
        'en' => 'For children up to 10 years',
        'ro' => 'Pentru copii până la 10 ani',
        _ => 'Für Kinder bis 10 Jahre',
      };

  String progress(int n, int total) => switch (lang) {
        'fr' => 'Exercice $n sur $total',
        'en' => 'Exercise $n of $total',
        'ro' => 'Exercițiul $n din $total',
        _ => 'Aufgabe $n von $total',
      };

  String starsLabel(int stars) => switch (lang) {
        'fr' => '$stars étoile${stars == 1 ? '' : 's'}',
        'en' => '$stars star${stars == 1 ? '' : 's'}',
        'ro' => stars == 1 ? '1 stea' : '$stars stele',
        _ => '$stars Stern${stars == 1 ? '' : 'e'}',
      };

  String get deChip => AppLocales.chips['de']!;
  String get frChip => AppLocales.chips['fr']!;
  String get enChip => AppLocales.chips['en']!;
  String get roChip => AppLocales.chips['ro']!;
}
