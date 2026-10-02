// The programmes bundled with the app.
//
// Each one is an ordinary plan file in assets/programs/, in exactly the format
// "Share a plan" writes, and goes in through the same import. Bundling them as
// files rather than as Dart data means there is one way a split gets into the
// app from outside, and that a programme here can be opened in a text editor,
// fixed, and checked by the same parser that reads a file a friend sent.
//
// What the file can't carry — the paragraph that tells you who a programme is
// for — lives in this catalogue instead, so the plan format stays plans only.
//
// The paragraph and the one-liner are translated (`programs…Summary` and
// `programs…Description` in the ARB files); the programme's name is not. It is
// also the name of the split it becomes, inside the file, and like the
// exercise names in it, that stays the same in every language.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../plan_share/data/plan_document.dart';

/// Who a programme is pitched at.
enum ProgramLevel {
  beginner('Beginner'),
  intermediate('Intermediate');

  const ProgramLevel(this.label);

  /// The English name. On screen use [localizedLabel].
  final String label;

  /// The name in the app's language, e.g. "Einsteiger".
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ProgramLevel.beginner => l10n.programsLevelBeginner,
    ProgramLevel.intermediate => l10n.programsLevelIntermediate,
  };
}

/// One programme shipped with the app.
class BundledProgram {
  const BundledProgram({
    required this.id,
    required this.name,
    required this.summary,
    required this.description,
    required this.level,
    required this.daysPerWeek,
  });

  /// Stable slug; also the file name under assets/programs/.
  final String id;

  /// Matches the split name inside the file (a test holds the two together),
  /// so what you pick in the browser is what lands in your split list.
  final String name;

  /// One line for the list.
  final String summary;

  /// A short paragraph for the detail screen: who it suits and how to run it.
  final String description;

  final ProgramLevel level;

  /// Training days in a normal week, as scheduled in the file.
  final int daysPerWeek;

  String get assetPath => 'assets/programs/$id.$planFileExtension';

  /// [summary] in the app's language. A programme added here without a
  /// translation shows its English line rather than nothing.
  String localizedSummary(AppLocalizations l10n) => switch (id) {
    'beginner_full_body' => l10n.programsBeginnerFullBodySummary,
    'full_body_5x5' => l10n.programsFullBody5x5Summary,
    'upper_lower' => l10n.programsUpperLowerSummary,
    'push_pull_legs' => l10n.programsPushPullLegsSummary,
    'percentage_strength' => l10n.programsPercentageStrengthSummary,
    'body_part_split' => l10n.programsBodyPartSplitSummary,
    _ => summary,
  };

  /// [description] in the app's language, with the same fallback.
  String localizedDescription(AppLocalizations l10n) => switch (id) {
    'beginner_full_body' => l10n.programsBeginnerFullBodyDescription,
    'full_body_5x5' => l10n.programsFullBody5x5Description,
    'upper_lower' => l10n.programsUpperLowerDescription,
    'push_pull_legs' => l10n.programsPushPullLegsDescription,
    'percentage_strength' => l10n.programsPercentageStrengthDescription,
    'body_part_split' => l10n.programsBodyPartSplitDescription,
    _ => description,
  };
}

/// Every bundled programme, in the order the browser lists them — easiest to
/// start with first.
const bundledPrograms = <BundledProgram>[
  BundledProgram(
    id: 'beginner_full_body',
    name: 'Beginner Full Body',
    summary: 'One machine-and-dumbbell session, three times a week',
    description:
        'A gentle first programme built on machines, cables and dumbbells, so '
        'there is no barbell technique to learn before you start. The same '
        'full-body session three times a week, with rep ranges: once you hit '
        'the top of the range on every set, add a little weight.',
    level: ProgramLevel.beginner,
    daysPerWeek: 3,
  ),
  BundledProgram(
    id: 'full_body_5x5',
    name: 'Full Body 5×5',
    summary: 'Two alternating barbell workouts, five sets of five',
    description:
        'A classic linear-progression programme for building a strength base '
        'on the big barbell lifts. Alternate workout A and workout B three '
        'days a week and add a small amount of weight each time you complete '
        'every rep. Simple, fast, and it works for months before it stops.',
    level: ProgramLevel.beginner,
    daysPerWeek: 3,
  ),
  BundledProgram(
    id: 'upper_lower',
    name: 'Upper / Lower',
    summary: 'Four days, each muscle trained twice a week',
    description:
        'Two upper-body and two lower-body days. Each opens with a heavy '
        'compound in a low rep range, then moves to higher-rep accessories, '
        'with arm and shoulder work paired as supersets to save time. A good '
        'next step once three full-body days stop being enough.',
    level: ProgramLevel.intermediate,
    daysPerWeek: 4,
  ),
  BundledProgram(
    id: 'push_pull_legs',
    name: 'Push / Pull / Legs',
    summary: 'Six days, the classic bodybuilding rotation',
    description:
        'Pressing muscles, pulling muscles and legs on their own days, run '
        'twice through the week. Lots of volume for building muscle, with '
        'arm work done as supersets. Demanding on time: if six days is too '
        'many, run each day once and take the weekend off.',
    level: ProgramLevel.intermediate,
    daysPerWeek: 6,
  ),
  BundledProgram(
    id: 'percentage_strength',
    name: 'Percentage Strength',
    summary: 'Four days, main lifts planned as a percentage of your 1RM',
    description:
        'One day each for squat, bench, deadlift and overhead press. The main '
        'lift is planned as a percentage of your one-rep max, and Gymfy works '
        'out the weight from your tested or estimated 1RM, rounded to plates '
        'you can load. Pairs well with a training block on the split, such as '
        'three weeks of training and a deload week.',
    level: ProgramLevel.intermediate,
    daysPerWeek: 4,
  ),
  BundledProgram(
    id: 'body_part_split',
    name: 'Body-Part Split',
    summary: 'Five days, one muscle group per day',
    description:
        'Chest, back, shoulders, arms and legs, each with a day to itself. '
        'Every muscle is trained hard once a week with plenty of exercises, '
        'and arm day runs as two supersets. Suits people who like long, '
        'focused sessions and can train five days in a row.',
    level: ProgramLevel.intermediate,
    daysPerWeek: 5,
  ),
];

/// Reads and parses one bundled programme.
///
/// Through [PlanDocument.decode], the same parser a file from a friend goes
/// through, so a bundled programme can't quietly rely on anything a shared
/// plan couldn't carry.
Future<PlanDocument> loadBundledProgram(
  BundledProgram program, {
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(program.assetPath);
  return PlanDocument.decode(source);
}

/// A bundled programme, parsed, by id.
final bundledProgramProvider = FutureProvider.family<PlanDocument, String>((
  ref,
  id,
) {
  final program = bundledPrograms.firstWhere((p) => p.id == id);
  return loadBundledProgram(program);
});
