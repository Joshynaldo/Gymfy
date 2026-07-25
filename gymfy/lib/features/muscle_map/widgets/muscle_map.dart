import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/theme/accent_color.dart';

part 'muscle_map.g.dart';

/// Which body diagram to show.
enum BodySide {
  front('assets/svg/body_front.svg'),
  back('assets/svg/body_back.svg');

  const BodySide(this.asset);

  /// The bundled SVG for this side.
  final String asset;
}

/// The neutral colour every muscle uses at intensity 0 — must match the
/// placeholder `fill` authored into the SVG files.
const _restColor = Color(0xFF4C5361);

/// Matches a muscle group's opening tag so we can rewrite just its fill,
/// e.g. `data-muscle="chest" fill="#4C5361"`.
final _muscleFill = RegExp(r'data-muscle="([a-z_]+)" fill="#[0-9A-Fa-f]{6}"');

/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.
@riverpod
Future<String> bodySvgTemplate(Ref ref, BodySide side) {
  return rootBundle.loadString(side.asset);
}

/// A body diagram whose muscles are tinted by how hard they've been worked.
///
/// [intensities] maps a `MuscleId` to a 0.0–1.0 value; each muscle is blended
/// from the neutral rest colour (0) toward the current accent colour (1).
/// Muscles absent from the map (or set to 0) stay neutral.
class MuscleMap extends ConsumerWidget {
  const MuscleMap({
    super.key,
    required this.side,
    required this.intensities,
  });

  final BodySide side;
  final Map<String, double> intensities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(bodySvgTemplateProvider(side));
    final accent = ref.watch(accentColorProvider);

    return AspectRatio(
      aspectRatio: 220 / 470,
      child: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load the body map.\n$error',
              textAlign: TextAlign.center),
        ),
        data: (template) {
          final svg = _tintMuscles(template, intensities, accent);
          return SvgPicture.string(svg, fit: BoxFit.contain);
        },
      ),
    );
  }
}

/// Rewrites each muscle group's fill in [svg] to reflect its intensity.
String _tintMuscles(
  String svg,
  Map<String, double> intensities,
  Color accent,
) {
  return svg.replaceAllMapped(_muscleFill, (match) {
    final id = match.group(1)!;
    final t = (intensities[id] ?? 0).clamp(0.0, 1.0);
    final color = Color.lerp(_restColor, accent, t)!;
    return 'data-muscle="$id" fill="${_toHex(color)}"';
  });
}

/// Formats a colour as an SVG `#RRGGBB` string (alpha dropped).
String _toHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
