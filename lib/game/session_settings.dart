import 'package:flutter/foundation.dart';

import '../l10n/app_locales.dart';

class SessionSettings extends ChangeNotifier {
  String locale = 'de';
  bool muted = false;

  void setLocale(String value) {
    final next = AppLocales.normalize(value);
    if (next == locale) return;
    locale = next;
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }
}
