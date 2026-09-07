import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'home_page.dart';

/// Leaves only the home screen on the stack.
///
/// [popUntil] `isFirst` is not enough after [Navigator.pushReplacement] of the
/// exercise (or a MaterialApp rebuild): the reward route can become first, so
/// Home would no-op or reveal another [ExercisePage]. Always replace the stack.
void goHome(BuildContext context) {
  unawaited(AppScope.of(context).sfx.transition());
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: Navigator.defaultRouteName),
      builder: (_) => const HomePage(),
    ),
    (route) => false,
  );
}

Future<T?> pushKidPage<T>(BuildContext context, Widget page) {
  unawaited(AppScope.of(context).sfx.transition());
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(builder: (_) => page),
  );
}
