// Basic smoke test: the app boots and shows its bottom navigation.

// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/main.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  testWidgets('Gymfy boots and shows the four main tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The default (Workout) tab reads splits from the database; feed it
          // an empty list so the test doesn't touch a real database and the
          // loading spinner (which never settles) is skipped.
          splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
        ],
        child: const GymfyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The bottom navigation bar is present...
    expect(find.byType(NavigationBar), findsOneWidget);

    // ...with all four main tab labels.
    for (final label in ['Workout', 'Exercises', 'Muscles', 'Progress']) {
      expect(find.text(label), findsAtLeastNWidgets(1));
    }
  });
}
