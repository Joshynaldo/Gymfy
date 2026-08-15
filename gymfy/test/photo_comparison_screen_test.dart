// The comparison screen must default to the widest span (oldest vs newest),
// state the gap between them, let either side be swapped, and explain itself
// when there aren't two photos to compare.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/photo_repository.dart';
import 'package:gymfy/features/progress/screens/photo_comparison_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  PhotoItem item(int id, int day, {String? note}) {
    return (
      photo: ProgressPhoto(
        id: id,
        date: DateTime(2026, 5, day),
        fileName: '2026-05-${day.toString().padLeft(2, '0')}_$id.jpg',
        note: note,
        createdAt: DateTime(2026, 5, day),
      ),
      // Deliberately missing on disk: the widget must fall back to its
      // placeholder rather than throw.
      path: '/nonexistent/photo_$id.jpg',
    );
  }

  // Newest first, as the repository streams it.
  final photos = [
    item(3, 30, note: 'front'),
    item(2, 16),
    item(1, 2, note: 'start'),
  ];

  Future<void> pump(WidgetTester tester, List<PhotoItem> items) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          progressPhotosProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: const MaterialApp(home: PhotoComparisonScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to oldest vs newest and shows the span', (tester) async {
    await pump(tester, photos);

    expect(tester.takeException(), isNull);
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    // 2 May on the left, 30 May on the right.
    expect(find.text('2 May'), findsOneWidget);
    expect(find.text('30 May'), findsOneWidget);
    // 28 days rounds to 4 weeks.
    expect(find.text('4 weeks apart'), findsOneWidget);
  });

  testWidgets('either side can be swapped for another photo', (tester) async {
    await pump(tester, photos);

    // Tap the "before" slot, then pick the middle photo from the sheet.
    await tester.tap(find.text('2 May'));
    await tester.pumpAndSettle();
    expect(find.text('Pick the "before" photo'), findsOneWidget);

    await tester.tap(find.text('16 May').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('16 May'), findsOneWidget);
    expect(find.text('2 May'), findsNothing); // swapped out
    expect(find.text('2 weeks apart'), findsOneWidget);
  });

  testWidgets('one photo is not a comparison', (tester) async {
    await pump(tester, [photos.first]);

    expect(find.text('Nothing to compare yet'), findsOneWidget);
    expect(find.text('Before'), findsNothing);
  });
}
