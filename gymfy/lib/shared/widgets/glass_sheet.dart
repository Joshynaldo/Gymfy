import 'package:flutter/material.dart';

import '../../app/theme/glass.dart';

/// The shell every bottom sheet in the app shares.
///
/// One widget rather than a shell per sheet: there were two before this, each
/// with its own blur radius and its own idea of how opaque a sheet is, which is
/// precisely how two surfaces in one app drift apart. Now both ask the material
/// what a sheet looks like.
///
/// A sheet is where the glass earns itself. It sits over the screen you came
/// from, so the blur has something to do and the light along its top lip has a
/// reason to be there — unlike a card, which lies directly on the backdrop and
/// would be blurring a smooth colour field into the same smooth colour field.
///
/// On the flat themes [GlassSurface] falls through to an opaque box in the
/// theme's own surface colour, which is what those themes have always drawn.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.title,
    this.handle = true,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final Widget child;

  /// Optional heading. Sheets that build their own header pass null.
  final String? title;

  /// The grab bar. Off for sheets that are dismissed by a button rather than a
  /// drag, where a handle promises a gesture the sheet does not really want.
  final bool handle;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      tier: GlassTier.sheet,
      // A Material inside the pane, not around it: rows in a sheet are often
      // ListTiles, and those paint their selection tint and ink onto the
      // nearest Material *ancestor*. With a painted surface in between, Flutter
      // asserts that the highlight may be invisible — and it is right.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (handle)
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [child] in a [GlassSheet].
///
/// Wraps [showModalBottomSheet] with the two settings every sheet here needs:
/// a transparent background — the sheet paints its own surface, and an opaque
/// one behind it would sit in front of the blur — and `isScrollControlled`, so
/// a tall sheet is allowed past the usual half-screen ceiling.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool handle = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: handle,
    builder: (context) =>
        GlassSheet(title: title, handle: handle, child: child),
  );
}
