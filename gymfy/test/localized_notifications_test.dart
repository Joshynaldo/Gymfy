// The rest-timer notifications are drawn by the system, not by a widget, so
// they get their words from the language provider instead of context.l10n.

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/l10n/app_language.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/data/notification_service.dart';

/// Records what would have been posted, and does nothing else.
class _RecordingPlugin implements FlutterLocalNotificationsPlugin {
  final posted = <({String? title, String? body, String? channel})>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #show) {
      final details =
          invocation.namedArguments[#notificationDetails]
              as NotificationDetails?;
      posted.add((
        title: invocation.namedArguments[#title] as String?,
        body: invocation.namedArguments[#body] as String?,
        channel: details?.android?.channelName,
      ));
    }
    // Every method the service calls returns a Future, and `Future<Null>` is
    // one of each of them (`Future<void>`, `Future<bool?>`).
    return Future<Null>.value();
  }
}

void main() {
  final german = lookupAppLocalizations(const Locale('de'));

  test(
    'without a language the notifications read as they always have',
    () async {
      final plugin = _RecordingPlugin();
      final service = NotificationService(plugin);

      await service.showRestRunning(seconds: 90, exerciseName: 'Bench Press');
      await service.notifyRestOver(exerciseName: 'Bench Press', vibrate: true);

      expect(plugin.posted, [
        (
          title: 'Resting',
          body: 'Bench Press',
          channel: 'Rest timer countdown',
        ),
        (
          title: 'Rest over',
          body: 'Next set of Bench Press',
          channel: 'Rest timer',
        ),
      ]);
    },
  );

  test('in German, with the exercise name left as it is', () async {
    final plugin = _RecordingPlugin();
    final service = NotificationService(plugin, strings: () => german);

    await service.showRestRunning(seconds: 90, exerciseName: 'Bench Press');
    await service.notifyRestOver(exerciseName: 'Bench Press', vibrate: true);

    expect(plugin.posted, [
      (title: 'Pause', body: 'Bench Press', channel: 'Pausen-Countdown'),
      (
        title: 'Pause vorbei',
        body: 'Nächster Satz: Bench Press',
        channel: 'Pausentimer',
      ),
    ]);
  });

  test('the language is asked for at each post, not once', () async {
    final plugin = _RecordingPlugin();
    var strings = englishLocalizations;
    final service = NotificationService(plugin, strings: () => strings);

    await service.notifyRestOver(exerciseName: 'Squat', vibrate: false);
    strings = german;
    await service.notifyRestOver(exerciseName: 'Squat', vibrate: false);

    expect(plugin.posted.map((p) => p.title), ['Rest over', 'Pause vorbei']);
  });

  test('code without a widget gets the language the app is shown in', () {
    final container = ProviderContainer(
      overrides: [
        storedAppLanguageProvider.overrideWith(
          (ref) => Stream.value(AppLanguage.german),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Before the stored value arrives the phone decides; once it has, the
    // stored choice does.
    container.listen(appLocalizationsProvider, (_, _) {});
    return Future<void>.delayed(Duration.zero, () {
      expect(container.read(appLocalizationsProvider).localeName, 'de');
    });
  });
}
