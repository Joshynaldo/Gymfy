import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/weekday.dart';

/// The weekday this phone's week starts on (ISO: 1 = Monday … 7 = Sunday).
///
/// From the device's own region rather than the app's localisations: Gymfy
/// ships in English only, so `Localizations.localeOf` always answers en_US —
/// and would start every German user's week on a Sunday.
///
/// Read once. The region changing while the app is open is rare enough that
/// the calendar and the weekly goals picking it up on the next launch is fine.
final firstWeekdayProvider = Provider<int>((ref) {
  return firstWeekdayFor(WidgetsBinding.instance.platformDispatcher.locale);
});
