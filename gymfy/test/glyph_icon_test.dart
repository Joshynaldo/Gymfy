// The design's own icons (MockupGlyph): each one must be a drawable SVG, and
// GlyphIcon must behave like an Icon — sized and coloured by the IconTheme
// unless told otherwise — so it can stand in anywhere an Icon would.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/glyph_icon.dart';

void main() {
  test('every glyph is an SVG flutter_svg can draw', () async {
    for (final glyph in MockupGlyph.values) {
      final info = await vg.loadPicture(SvgStringLoader(glyph.svg), null);
      expect(info.size, const Size(20, 20), reason: glyph.name);
      info.picture.dispose();
    }
  });

  Future<Size> sizeIn(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Center(child: child)));
    return tester.getSize(find.byType(GlyphIcon));
  }

  testWidgets('takes its size from the IconTheme, like an Icon', (
    tester,
  ) async {
    final size = await sizeIn(
      tester,
      const IconTheme(
        data: IconThemeData(size: 31),
        child: GlyphIcon(MockupGlyph.home),
      ),
    );
    expect(size, const Size(31, 31));
  });

  testWidgets('an explicit size wins over the theme', (tester) async {
    final size = await sizeIn(
      tester,
      const IconTheme(
        data: IconThemeData(size: 31),
        child: GlyphIcon(MockupGlyph.home, size: 18),
      ),
    );
    expect(size, const Size(18, 18));
  });

  testWidgets('paints in the IconTheme colour', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(color: Color(0xFF7C6BFF)),
          child: GlyphIcon(MockupGlyph.progress),
        ),
      ),
    );
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      picture.colorFilter,
      const ColorFilter.mode(Color(0xFF7C6BFF), BlendMode.srcIn),
    );
  });

  testWidgets('is silent to screen readers unless given a label', (
    tester,
  ) async {
    // Next to a label, an icon read aloud says the same thing twice.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            GlyphIcon(MockupGlyph.help),
            GlyphIcon(MockupGlyph.settings, semanticLabel: 'Settings'),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    handle.dispose();
  });
}
