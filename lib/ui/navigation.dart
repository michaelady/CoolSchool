import 'package:flutter/material.dart';

import '../content/models.dart';
import 'home_page.dart';

/// Leaves only the home screen on the stack.
///
/// [popUntil] `isFirst` is not enough after [Navigator.pushReplacement] of the
/// exercise (or a MaterialApp rebuild): the reward route can become first, so
/// Home would no-op or reveal another [ExercisePage]. Always replace the stack.
void goHome(BuildContext context, {ContentPack? pack}) {
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: Navigator.defaultRouteName),
      builder: (_) => HomePage(initialPack: pack),
    ),
    (route) => false,
  );
}
