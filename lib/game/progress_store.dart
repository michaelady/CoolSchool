import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore({this.persist = true});

  final bool persist;
  final Map<String, int> _stars = {};
  final Set<String> _completed = {};
  static const _prefix = 'stars.';
  static const _donePrefix = 'done.';

  Map<String, int> get starsByLevelId => Map.unmodifiable(_stars);

  /// Levels the player has finished at least once (any score).
  ///
  /// Starred levels count as finished so older installs without a `done.*`
  /// flag still unlock the next difficulty.
  Set<String> get completedLevelIds => {
        ..._completed,
        for (final entry in _stars.entries)
          if (entry.value > 0) entry.key,
      };

  int starsFor(String levelId) => _stars[levelId] ?? 0;

  bool hasCompleted(String levelId) => completedLevelIds.contains(levelId);

  Future<void> load() async {
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        final value = prefs.getInt(key);
        if (value == null) continue;
        _stars[key.substring(_prefix.length)] = value;
      } else if (key.startsWith(_donePrefix) && prefs.getBool(key) == true) {
        _completed.add(key.substring(_donePrefix.length));
      }
    }
    notifyListeners();
  }

  /// Marks the level finished (unlocks the next one) and keeps the best star
  /// count. A 0-star finish still counts as completed.
  Future<void> recordBest(String levelId, int stars) async {
    var changed = false;
    if (!_completed.contains(levelId)) {
      _completed.add(levelId);
      changed = true;
    }
    final previous = _stars[levelId] ?? 0;
    if (stars > previous) {
      _stars[levelId] = stars;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_donePrefix$levelId', true);
    if (stars > previous) {
      await prefs.setInt('$_prefix$levelId', stars);
    }
  }
}
