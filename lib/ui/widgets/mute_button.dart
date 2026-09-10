import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../l10n/strings.dart';
import 'kid_chrome.dart';

/// Session mute control bound to [SessionSettings], not local widget state.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        final i18n = I18n(scope.settings.locale);
        final muted = scope.settings.muted;
        return RoundIconButton(
          key: const ValueKey<String>('mute-button'),
          icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          tooltip: muted ? i18n.unmute : i18n.mute,
          selected: muted,
          onPressed: () {
            scope.settings.toggleMute();
            if (scope.settings.muted) {
              unawaited(scope.speech.stop());
            }
          },
        );
      },
    );
  }
}
