import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Static utility service for widget-to-image capture and native share-sheet
/// integration.
///
/// Capture approach: Flutter's built-in [RenderRepaintBoundary.toImage] —
/// no additional screenshot package required.
///
/// Share approach: [share_plus] via [Share.shareXFiles]. The generated PNG is
/// saved to the device's temporary directory before sharing, which is the most
/// reliable cross-platform path.
///
/// Events emitted:
///   ShareImageGenerated — after [toImage] succeeds
///   ShareRequested      — after [Share.shareXFiles] is called
class ShareService {
  ShareService._();

  /// Captures the widget identified by [repaintBoundaryKey] as a PNG and
  /// opens the native system share sheet.
  ///
  /// Parameters:
  ///   [repaintBoundaryKey] — must be attached to a [RepaintBoundary] that is
  ///     currently rendered on screen.
  ///   [pixelRatio]  — capture resolution (3.0 = 3× device pixel density,
  ///     suitable for social media).
  ///   [shareText]   — optional caption shown in the share sheet.
  ///   [fileName]    — name of the generated PNG file.
  ///
  /// Throws if the boundary is not in the widget tree or image encoding fails.
  static Future<void> shareWidget({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = 3.0,
    String shareText = 'من الذيب في مجموعتنا؟ 🐺 #مين_الذيب',
    String fileName = 'meen_al_theeb_result.png',
  }) async {
    // Allow one extra frame for any pending paint to complete
    await Future.delayed(const Duration(milliseconds: 20));

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('RepaintBoundary is not in the widget tree');
    }

    // Capture as raw image at the requested pixel ratio
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    // Encode to PNG bytes — ShareImageGenerated event
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode image to PNG');
    }
    final bytes = byteData.buffer.asUint8List();

    // Write to temp directory (required by share_plus on iOS/Android)
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    // Open native share sheet — ShareRequested event
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png', name: fileName)],
      text: shareText,
    );
  }

  /// Simple text-only share (fallback when no image is available).
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
