import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/settings_repository.dart';
import '../../../shared/models/body_measurement.dart';
import '../../progress/data/measurements_repository.dart';

part 'onboarding_repository.g.dart';

/// Setting key for "the user has been through onboarding".
const onboardingCompleteSetting = 'onboarding_complete';

/// Setting key for what to call the user.
const userNameSetting = 'user_name';

/// True once onboarding has been finished.
///
/// Deliberately strict: only the exact string `true` counts. Anything else —
/// unset, empty, junk — reads as "not yet", so the worst case is showing
/// onboarding again rather than locking a new user out of it.
final onboardingCompleteProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(onboardingCompleteSetting)
      .map((raw) => raw == 'true');
});

/// What the user asked to be called, or null if they skipped it.
final userNameProvider = StreamProvider<String?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(userNameSetting)
      .map((raw) {
        final name = raw?.trim();
        return name == null || name.isEmpty ? null : name;
      });
});

/// Writes what onboarding collected.
class OnboardingRepository {
  OnboardingRepository(this._settings, this._measurements);

  final SettingsRepository _settings;
  final MeasurementsRepository _measurements;

  /// Saves the answers and marks onboarding done.
  ///
  /// Both answers are optional, because both are skippable in the UI — a blank
  /// name or an unparseable weight arrives here as null and is simply not
  /// written, rather than stored as an empty string or a zero.
  ///
  /// The accent isn't passed in: the picker writes it as soon as it's tapped so
  /// the app re-themes live, which also means there's nothing left to save here.
  ///
  /// Bodyweight goes into the measurements table, not a setting of its own. That
  /// is the same row the progress charts and strength ranks read, so day one
  /// becomes the first point on the weight timeline instead of a duplicate
  /// number that can disagree with it.
  Future<void> finish({required String? name, required double? bodyweightKg}) async {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _settings.write(userNameSetting, trimmed);
    }

    if (bodyweightKg != null && bodyweightKg > 0) {
      await _measurements.setField(
        day: DateTime.now(),
        field: MeasurementField.weight,
        value: bodyweightKg,
      );
    }

    // Written last, so a failure part-way through leaves onboarding showing
    // again rather than silently swallowing the answers.
    await _settings.write(onboardingCompleteSetting, 'true');
  }
}

/// App-wide access to the [OnboardingRepository].
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepository(
    ref.watch(settingsRepositoryProvider),
    ref.watch(measurementsRepositoryProvider),
  );
}
