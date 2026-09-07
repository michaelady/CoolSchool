import 'package:flutter/foundation.dart';

class SessionSettings extends ChangeNotifier {
  String locale = 'de';
  bool muted = false;

  void setLocale(String value) {
    if (value == locale) return;
    locale = value.startsWith('fr') ? 'fr' : 'de';
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }
}
