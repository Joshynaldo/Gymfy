/// Where an exercise's animation might be bundled.
///
/// Seed data declares one path per exercise, `assets/exercises/<id>.gif`, but
/// what actually ships can be an animated WebP instead — the same loop at a
/// fraction of the size, and all of it lands in the download because there is
/// no server to stream from. Rather than rewrite 78 seed entries every time
/// that choice is revisited, the declared path is treated as the *convention*
/// and the extension is resolved at load.
///
/// The order is deliberate: WebP first, so a project that ships both formats
/// serves the smaller one, and a single hand-made GIF can still override
/// nothing — it is only reached when no WebP exists for that exercise.
List<String> previewCandidates(String declaredPath) {
  final dot = declaredPath.lastIndexOf('.');
  if (dot <= 0) return [declaredPath];
  final stem = declaredPath.substring(0, dot);
  return ['$stem.webp', declaredPath];
}
