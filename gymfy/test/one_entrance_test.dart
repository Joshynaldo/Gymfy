// A screen gets one entrance, not two.
//
// The bug: a pushed route already animates in — `GymfyPageTransitionsBuilder`
// slides it 10% from the right and fades it 0→1 over the first 55%. Seven
// screens then wrapped their *entire body* in `FadeSlideIn`, which fades 0→1
// again and lifts 8px, at the same time.
//
// Two fades on the same pixels multiply. Measured mid-push, the content sat at
// 0.875 of an opacity that was itself still climbing, and it was travelling
// right-to-left and bottom-to-top at once. What you see is the content
// lagging behind the screen it is on and then catching up in a rush — which
// is what "the animations are buggy" looked like, on Settings, Help, the two
// calculators, Export, the plate calculator and the exercise detail screen.
//
// This is checked by reading the source rather than by driving a widget,
// because the content genuinely cannot tell. Inside a route's own subtree
// Flutter proxies `ModalRoute.animation` to `kAlwaysCompleteAnimation` — the
// transition is applied *above* the modal scope, so from underneath there is
// nothing to detect. (That was the first attempt at this fix, and the probe
// that killed it: the route printed `animation: AnimationController(0.000)`
// while the content was handed a completed one.) The rule therefore has to
// live where the decision is made, at the call site.
//
// Same approach as `one_wheel_test.dart`: a rule about how the app is built,
// enforced against the files themselves.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen file in the app.
List<File> _screenFiles() {
  return Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.replaceAll(r'\', '/').contains('/screens/'))
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

/// Strips `//` comments, so prose describing the rule cannot trip it.
String _code(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('no screen wraps its whole body in an unkeyed FadeSlideIn', () {
    // The rule is "its child is a scroll view", which is the crisp version of
    // "it is the whole screen". A screen body is a ListView or a
    // CustomScrollView; a list *row* never is. That distinction does the work
    // without having to guess from the surrounding syntax — `return
    // FadeSlideIn(` is a body in one file and an `itemBuilder` row in the
    // next, so the spelling alone says nothing. Rows are exactly what this
    // widget is for and must keep animating.
    //
    // A `key:` is the other exception: a keyed wrapper replays when the key
    // changes, which is a content swap inside a screen already on display.
    // `progress_screen.dart` keys its body on the selected segment and is
    // right to.
    final offenders = <String>[];

    for (final file in _screenFiles()) {
      final code = _code(file.readAsStringSync());
      for (final match in RegExp(
        r'FadeSlideIn\(\s*(?:key:[^,]*,\s*)?child:\s*'
        r'(ListView|CustomScrollView|SingleChildScrollView)\(',
      ).allMatches(code)) {
        if (match.group(0)!.contains('key:')) continue;
        offenders.add('${file.path.replaceAll(r'\', '/')} (${match.group(1)})');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These screens play their own entrance on top of the page '
          'transition, which already slides and fades them in. Let the route '
          'carry the screen; use FadeSlideIn for content arriving into a '
          'screen that is already there.',
    );
  });

  test('and the rule is actually looking at something', () {
    // A guard on the guard. If the walk above ever stops finding screen files
    // — a folder rename, a changed layout — the test would pass by looking at
    // nothing at all, which is the failure mode of every source-reading test.
    final files = _screenFiles();
    expect(files.length, greaterThan(20));
    expect(
      files.any((f) => f.path.contains('settings_screen')),
      isTrue,
      reason: 'the screen this rule was written for should be in the sweep',
    );
  });

  test('FadeSlideIn is still used where it belongs', () {
    // The other direction. Deleting the widget everywhere would satisfy the
    // first test perfectly and would throw away the animation the developer
    // asked to keep. Rows arriving in a list are the case it exists for.
    final users = _screenFiles()
        .where((f) => _code(f.readAsStringSync()).contains('FadeSlideIn('))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();

    expect(
      users.length,
      greaterThanOrEqualTo(4),
      reason: 'list rows and keyed content swaps should still animate',
    );
  });
}
