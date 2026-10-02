import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The Lucide icons the app uses (https://lucide.dev), drawn from the font in
/// `assets/fonts/lucide/`.
///
/// Lucide is the line-icon set every icon outside [MockupGlyph] comes from:
/// round-capped two-pixel strokes on a 24px grid, the same style as the
/// design's own drawings. It is vendored rather than used through a package
/// because the package ships six extra stroke-weight fonts the app never
/// draws, and Flutter can't leave a dependency's fonts out: about 1.4 MB of
/// every download for nothing. The one font here is tree-shaken at release
/// build down to the glyphs below.
///
/// The font is `lucide.ttf` from lucide_icons_flutter 3.1.21, which packages
/// Lucide's own icon font. To add an icon, take its codepoint from Lucide's
/// codepoints for that font (in the package, `assets/codepoints.json`, keyed
/// by the kebab-case name) and add a constant here.
///
/// Licensed ISC (with some icons MIT, from Feather); the full text is in
/// `assets/fonts/lucide/LICENSE.txt` and is registered with the app's
/// licences by [registerLucideLicense].
abstract final class LucideIcons {
  static const _font = 'Lucide';

  /// archive
  static const IconData archive = IconData(0xe041, fontFamily: _font);

  /// archive-restore
  static const IconData archiveRestore = IconData(0xe2cd, fontFamily: _font);

  /// arrow-left-right
  static const IconData arrowLeftRight = IconData(0xe24a, fontFamily: _font);

  /// arrow-up-down
  static const IconData arrowUpDown = IconData(0xe37d, fontFamily: _font);

  /// bed-single
  static const IconData bedSingle = IconData(0xe2c3, fontFamily: _font);

  /// bell
  static const IconData bell = IconData(0xe059, fontFamily: _font);

  /// book-open
  static const IconData bookOpen = IconData(0xe05f, fontFamily: _font);

  /// braces
  static const IconData braces = IconData(0xe36a, fontFamily: _font);

  /// cake
  static const IconData cake = IconData(0xe344, fontFamily: _font);

  /// calendar
  static const IconData calendar = IconData(0xe063, fontFamily: _font);

  /// calendar-check
  static const IconData calendarCheck = IconData(0xe2b7, fontFamily: _font);

  /// calendar-cog
  static const IconData calendarCog = IconData(0xe5ed, fontFamily: _font);

  /// calendar-days
  static const IconData calendarDays = IconData(0xe2b9, fontFamily: _font);

  /// calendar-range
  static const IconData calendarRange = IconData(0xe2bd, fontFamily: _font);

  /// calendar-sync
  static const IconData calendarSync = IconData(0xe636, fontFamily: _font);

  /// calendar-x
  static const IconData calendarX = IconData(0xe2be, fontFamily: _font);

  /// chart-column
  static const IconData chartColumn = IconData(0xe2a3, fontFamily: _font);

  /// chart-line
  static const IconData chartLine = IconData(0xe2a5, fontFamily: _font);

  /// chart-pie
  static const IconData chartPie = IconData(0xe06b, fontFamily: _font);

  /// check
  static const IconData check = IconData(0xe06c, fontFamily: _font);

  /// chevron-down
  static const IconData chevronDown = IconData(0xe06d, fontFamily: _font);

  /// chevron-left
  static const IconData chevronLeft = IconData(0xe06e, fontFamily: _font);

  /// chevron-right
  static const IconData chevronRight = IconData(0xe06f, fontFamily: _font);

  /// circle
  static const IconData circle = IconData(0xe076, fontFamily: _font);

  /// circle-alert
  static const IconData circleAlert = IconData(0xe077, fontFamily: _font);

  /// circle-check
  static const IconData circleCheck = IconData(0xe226, fontFamily: _font);

  /// circle-dot
  static const IconData circleDot = IconData(0xe345, fontFamily: _font);

  /// circle-help
  static const IconData circleHelp = IconData(0xe082, fontFamily: _font);

  /// clock
  static const IconData clock = IconData(0xe087, fontFamily: _font);

  /// code
  static const IconData code = IconData(0xe093, fontFamily: _font);

  /// columns-2
  static const IconData columns2 = IconData(0xe098, fontFamily: _font);

  /// delete
  static const IconData delete = IconData(0xe0ae, fontFamily: _font);

  /// download
  static const IconData download = IconData(0xe0b2, fontFamily: _font);

  /// dumbbell
  static const IconData dumbbell = IconData(0xe3a1, fontFamily: _font);

  /// ellipsis-vertical
  static const IconData ellipsisVertical = IconData(0xe0b7, fontFamily: _font);

  /// external-link
  static const IconData externalLink = IconData(0xe0b9, fontFamily: _font);

  /// file-text
  static const IconData fileText = IconData(0xe0cc, fontFamily: _font);

  /// flag
  static const IconData flag = IconData(0xe0d1, fontFamily: _font);

  /// flame
  static const IconData flame = IconData(0xe0d2, fontFamily: _font);

  /// folder
  static const IconData folder = IconData(0xe0d7, fontFamily: _font);

  /// folder-open
  static const IconData folderOpen = IconData(0xe247, fontFamily: _font);

  /// footprints
  static const IconData footprints = IconData(0xe3b9, fontFamily: _font);

  /// funnel
  static const IconData funnel = IconData(0xe0dc, fontFamily: _font);

  /// gauge
  static const IconData gauge = IconData(0xe1bf, fontFamily: _font);

  /// grid-3x-3
  static const IconData grid3x3 = IconData(0xe0e9, fontFamily: _font);

  /// grip-horizontal
  static const IconData gripHorizontal = IconData(0xe0ea, fontFamily: _font);

  /// heart
  static const IconData heart = IconData(0xe0f2, fontFamily: _font);

  /// heart-off
  static const IconData heartOff = IconData(0xe295, fontFamily: _font);

  /// history
  static const IconData history = IconData(0xe1f5, fontFamily: _font);

  /// image
  static const IconData image = IconData(0xe0f6, fontFamily: _font);

  /// image-off
  static const IconData imageOff = IconData(0xe1c0, fontFamily: _font);

  /// image-plus
  static const IconData imagePlus = IconData(0xe1f7, fontFamily: _font);

  /// images
  static const IconData images = IconData(0xe5c4, fontFamily: _font);

  /// inbox
  static const IconData inbox = IconData(0xe0f7, fontFamily: _font);

  /// info
  static const IconData info = IconData(0xe0f9, fontFamily: _font);

  /// languages
  static const IconData languages = IconData(0xe0fe, fontFamily: _font);

  /// link
  static const IconData link = IconData(0xe102, fontFamily: _font);

  /// list-checks
  static const IconData listChecks = IconData(0xe1d0, fontFamily: _font);

  /// list-plus
  static const IconData listPlus = IconData(0xe23f, fontFamily: _font);

  /// mail
  static const IconData mail = IconData(0xe10f, fontFamily: _font);

  /// medal
  static const IconData medal = IconData(0xe36f, fontFamily: _font);

  /// message-circle
  static const IconData messageCircle = IconData(0xe116, fontFamily: _font);

  /// minus
  static const IconData minus = IconData(0xe11c, fontFamily: _font);

  /// moon
  static const IconData moon = IconData(0xe11e, fontFamily: _font);

  /// notebook-text
  static const IconData notebookText = IconData(0xe598, fontFamily: _font);

  /// palette
  static const IconData palette = IconData(0xe1dd, fontFamily: _font);

  /// pause
  static const IconData pause = IconData(0xe12e, fontFamily: _font);

  /// pencil
  static const IconData pencil = IconData(0xe1f9, fontFamily: _font);

  /// percent
  static const IconData percent = IconData(0xe132, fontFamily: _font);

  /// person-standing
  static const IconData personStanding = IconData(0xe21e, fontFamily: _font);

  /// play
  static const IconData play = IconData(0xe13c, fontFamily: _font);

  /// plus
  static const IconData plus = IconData(0xe13d, fontFamily: _font);

  /// repeat
  static const IconData repeat = IconData(0xe146, fontFamily: _font);

  /// rotate-ccw
  static const IconData rotateCcw = IconData(0xe148, fontFamily: _font);

  /// rows-3
  static const IconData rows3 = IconData(0xe58a, fontFamily: _font);

  /// ruler
  static const IconData ruler = IconData(0xe14b, fontFamily: _font);

  /// scale
  static const IconData scale = IconData(0xe212, fontFamily: _font);

  /// search
  static const IconData search = IconData(0xe151, fontFamily: _font);

  /// search-x
  static const IconData searchX = IconData(0xe4ad, fontFamily: _font);

  /// share
  static const IconData share = IconData(0xe155, fontFamily: _font);

  /// shield-check
  static const IconData shieldCheck = IconData(0xe1ff, fontFamily: _font);

  /// sigma
  static const IconData sigma = IconData(0xe201, fontFamily: _font);

  /// sliders-horizontal
  static const IconData slidersHorizontal = IconData(0xe29a, fontFamily: _font);

  /// sparkles
  static const IconData sparkles = IconData(0xe412, fontFamily: _font);

  /// square
  static const IconData square = IconData(0xe167, fontFamily: _font);

  /// sticky-note
  static const IconData stickyNote = IconData(0xe303, fontFamily: _font);

  /// table
  static const IconData table = IconData(0xe17d, fontFamily: _font);

  /// timer
  static const IconData timer = IconData(0xe1e0, fontFamily: _font);

  /// trash-2
  static const IconData trash2 = IconData(0xe18e, fontFamily: _font);

  /// trending-down
  static const IconData trendingDown = IconData(0xe190, fontFamily: _font);

  /// trending-up
  static const IconData trendingUp = IconData(0xe191, fontFamily: _font);

  /// trophy
  static const IconData trophy = IconData(0xe373, fontFamily: _font);

  /// user
  static const IconData user = IconData(0xe19f, fontFamily: _font);

  /// users
  static const IconData users = IconData(0xe1a4, fontFamily: _font);

  /// utensils
  static const IconData utensils = IconData(0xe2f6, fontFamily: _font);

  /// vibrate
  static const IconData vibrate = IconData(0xe223, fontFamily: _font);

  /// weight
  static const IconData weight = IconData(0xe530, fontFamily: _font);

  /// x
  static const IconData x = IconData(0xe1b2, fontFamily: _font);

  /// zap
  static const IconData zap = IconData(0xe1b4, fontFamily: _font);
}

/// Adds Lucide's licence to the app's licence registry. A package's licence
/// would be collected automatically; a vendored font's has to be added.
void registerLucideLicense() {
  LicenseRegistry.addLicense(
    () => Stream.value(
      const LicenseEntryWithLineBreaks(['Lucide'], _lucideLicense),
    ),
  );
}

const _lucideLicense = r'''
ISC License

Copyright (c) 2026 Lucide Icons and Contributors

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

---

The following Lucide icons are derived from the Feather project:

airplay, alert-circle, alert-octagon, alert-triangle, aperture, arrow-down-circle, arrow-down-left, arrow-down-right, arrow-down, arrow-left-circle, arrow-left, arrow-right-circle, arrow-right, arrow-up-circle, arrow-up-left, arrow-up-right, arrow-up, at-sign, calendar, cast, check, chevron-down, chevron-left, chevron-right, chevron-up, chevrons-down, chevrons-left, chevrons-right, chevrons-up, circle, clipboard, clock, code, columns, command, compass, corner-down-left, corner-down-right, corner-left-down, corner-left-up, corner-right-down, corner-right-up, corner-up-left, corner-up-right, crosshair, database, divide-circle, divide-square, dollar-sign, download, external-link, feather, frown, hash, headphones, help-circle, info, italic, key, layout, life-buoy, link-2, link, loader, lock, log-in, log-out, maximize, meh, minimize, minimize-2, minus-circle, minus-square, minus, monitor, moon, more-horizontal, more-vertical, move, music, navigation-2, navigation, octagon, pause-circle, percent, plus-circle, plus-square, plus, power, radio, rss, search, server, share, shopping-bag, sidebar, smartphone, smile, square, table-2, tablet, target, terminal, trash-2, trash, triangle, tv, type, upload, x-circle, x-octagon, x-square, x, zoom-in, zoom-out

The MIT License (MIT) (for the icons listed above)

Copyright (c) 2013-present Cole Bemis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';
