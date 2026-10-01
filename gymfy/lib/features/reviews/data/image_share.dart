import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Hands an image to Android's share sheet.
///
/// A hand-written platform channel rather than `share_plus`, which cannot be
/// built alongside `file_picker` on this toolchain (see pubspec.yaml) — the
/// same reasoning, and the same shape, as the watch bridge. The Kotlin half is
/// `ShareBridge.kt`: it wraps the file in a `content://` URI from the app's own
/// FileProvider and fires `ACTION_SEND`. Nothing leaves the phone except
/// through whichever app the user picks in the sheet.
class ImageShareBridge {
  const ImageShareBridge([this._channel = channel]);

  final MethodChannel _channel;

  static const channel = MethodChannel('de.kopten.gymfy/share');

  /// The folder, inside the app's cache, that the FileProvider is allowed to
  /// hand out. Must match `res/xml/share_paths.xml` — anything outside it is
  /// refused on the Kotlin side, which is the point.
  static const cacheFolder = 'share';

  /// Whether this platform has the share half at all. On iOS, desktop and in
  /// tests there is no handler, so the caller goes straight to saving.
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens the share sheet for the PNG at [path]. Returns false when sharing
  /// is not possible here — no handler, or Android said no — so the caller
  /// can fall back; never throws.
  Future<bool> sharePng(String path, {required String title}) async {
    if (!supported) return false;
    try {
      final shown = await _channel.invokeMethod<bool>('shareImage', {
        'path': path,
        'mimeType': 'image/png',
        'title': title,
      });
      return shown ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// How a share attempt ended.
enum ShareOutcome {
  /// The share sheet opened.
  shared,

  /// Sharing was not possible, and the image was saved instead.
  saved,

  /// The save dialog was dismissed.
  cancelled,
}

/// Shares [bytes] as `fileName`, or — when the share sheet cannot open —
/// offers to save them instead.
///
/// The three steps are passed in so the fallback can be tested without a
/// phone: [writeTemp] puts the bytes where the FileProvider can reach them,
/// [share] opens the sheet, [save] is the system save dialog and answers
/// whether a file was written. The defaults are the real ones.
Future<ShareOutcome> shareOrSaveImage(
  Uint8List bytes, {
  required String fileName,
  required String title,
  Future<String> Function(Uint8List bytes, String fileName)? writeTemp,
  Future<bool> Function(String path, String title)? share,
  Future<bool> Function(Uint8List bytes, String fileName)? save,
}) async {
  final write = writeTemp ?? writeShareFile;
  final open =
      share ??
      (path, title) => const ImageShareBridge().sharePng(path, title: title);
  final keep = save ?? _saveWithPicker;

  var shared = false;
  try {
    shared = await open(await write(bytes, fileName), title);
  } catch (_) {
    // A cache folder that can't be written is one more reason to save.
    shared = false;
  }
  if (shared) return ShareOutcome.shared;

  return await keep(bytes, fileName)
      ? ShareOutcome.saved
      : ShareOutcome.cancelled;
}

/// Writes [bytes] into the shareable cache folder and returns the path.
///
/// One file per name, overwritten: the cache is the system's to clear, and a
/// month's review shared twice is the same picture.
Future<String> writeShareFile(Uint8List bytes, String fileName) async {
  final cache = await getTemporaryDirectory();
  final dir = Directory('${cache.path}/${ImageShareBridge.cacheFolder}');
  if (!dir.existsSync()) await dir.create(recursive: true);
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<bool> _saveWithPicker(Uint8List bytes, String fileName) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: 'Save image',
    fileName: fileName,
    bytes: bytes,
    mimeType: 'image/png',
  );
  return saved != null;
}

/// Renders whatever [boundary] holds as a PNG.
///
/// [pixelRatio] 3 makes a 360-point-wide card about 1080 pixels across — sharp
/// on any phone it is sent to, and still a small file.
Future<Uint8List> capturePng(
  RenderRepaintBoundary boundary, {
  double pixelRatio = 3,
}) async {
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('the image could not be encoded');
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
