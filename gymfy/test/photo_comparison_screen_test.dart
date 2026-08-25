// The comparison screen overlays the two photos and fades between them. It must
// default to the widest span (oldest vs newest), start mid-fade so both are
// visible, state the gap between them, let either photo be swapped, and explain
// itself when there aren't two to compare.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/photo_repository.dart';
import 'package:gymfy/features/progress/screens/photo_comparison_screen.dart';
import 'package:gymfy/features/progress/widgets/photo_file_image.dart';
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

  /// The opacity each photo is currently drawn at, oldest first.
  ///
  /// Read off the widgets rather than off the slider: the slider's value only
  /// matters insofar as it reaches the images, and this is the thing that would
  /// actually be broken if it didn't.
  List<double> opacities(WidgetTester tester) {
    return tester
        .widgetList<PhotoFileImage>(find.byType(PhotoFileImage))
        .map((image) => image.opacity)
        .toList();
  }

  testWidgets('defaults to oldest vs newest and shows the span', (tester) async {
    await pump(tester, photos);

    expect(tester.takeException(), isNull);
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(find.text('2 May'), findsOneWidget);
    expect(find.text('30 May'), findsOneWidget);
    // 28 days rounds to 4 weeks.
    expect(find.text('4 weeks apart'), findsOneWidget);
  });

  testWidgets('both photos are on screen at once, half faded', (tester) async {
    await pump(tester, photos);

    // The overlay is the whole point of the screen, so it has to be visible
    // before anything is touched — opening on either extreme would look like
    // one photo was simply missing.
    expect(find.byType(PhotoFileImage), findsNWidgets(2));
    expect(opacities(tester), [0.5, 0.5]);
  });

  testWidgets('the slider fades from the old photo to the new one', (
    tester,
  ) async {
    await pump(tester, photos);

    // Drag the thumb to the far right: only the newer photo should remain.
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();

    final atEnd = opacities(tester);
    expect(atEnd[0], 1.0); // after
    expect(atEnd[1], 0.0); // before

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();

    final atStart = opacities(tester);
    expect(atStart[0], 0.0);
    expect(atStart[1], 1.0);
  });

  testWidgets('the two photos always sum to fully opaque', (tester) async {
    await pump(tester, photos);

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();

    // Anything else and the background shows through mid-fade, washing both
    // bodies out against the surface colour just when you're comparing them.
    final shown = opacities(tester);
    expect(shown[0] + shown[1], closeTo(1.0, 0.0001));
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
