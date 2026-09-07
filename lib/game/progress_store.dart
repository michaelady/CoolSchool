import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore({this.persist = true});

  final bool persist;
  final Map<String, int> _stars = {};
  static const _prefix = 'stars.';

  Map<String, int> get starsByLevelId => Map.unmodifiable(_stars);

  int starsFor(String levelId) => _stars[levelId] ?? 0;

  Future<void> load() async {
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final value = prefs.getInt(key);
      if (value == null) continue;
      _stars[key.substring(_prefix.length)] = value;
    }
    notifyListeners();
  }

  Future<void> recordBest(String levelId, int stars) async {
    final previous = _stars[levelId] ?? 0;
    if (stars <= previous) return;
    _stars[levelId] = stars;
    notifyListeners();
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$levelId', stars);
  }
}
