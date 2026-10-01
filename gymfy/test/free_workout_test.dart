// Starting a free workout: a session with no planned day, opened straight
// away — unless a workout is already running, which is opened instead.
//
// The repository is faked: drift's native database does not make progress
// inside a widget test's fake clock, and what a free session looks like in the
// database is already covered in session_exercises_test.dart.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/widgets/free_workout.dart';
import 'package:gymfy/shared/database/app_database.dart';

/// Hands out session 7 for a new free workout, and remembers the name asked
/// for. [running] is the workout already in progress, if any.
class _FakeSessions extends SessionRepository {
  _FakeSessions(super.db, {this.running});

  final WorkoutSession? running;
  final started = <String>[];

  @override
  Stream<WorkoutSession?> watchInProgressSession() => Stream.value(running);

  @override
  Future<int> startFreeSession({required String name}) async {
    started.add(name);
    return 7;
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// A two-route app: a button that starts a free workout, and a stand-in for
  /// the session screen that says which session it opened.
  Future<void> pump(WidgetTester tester, SessionRepository sessions) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => startFreeWorkout(context, ref),
                child: const Text('start'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/workout/session/:id',
          builder: (context, state) =>
              Text('session ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(sessions)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('creates a free session and opens it', (tester) async {
    final sessions = _FakeSessions(db);
    await pump(tester, sessions);

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(sessions.started, [freeWorkoutName]);
    expect(find.text('session 7'), findsOneWidget);
  });

  testWidgets('opens the running workout instead of a second one', (
    tester,
  ) async {
    final sessions = _FakeSessions(
      db,
      running: WorkoutSession(
        id: 3,
        name: 'Push',
        startedAt: DateTime(2026, 9, 30, 18),
      ),
    );
    await pump(tester, sessions);

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(sessions.started, isEmpty);
    expect(find.text('session 3'), findsOneWidget);
  });
}
