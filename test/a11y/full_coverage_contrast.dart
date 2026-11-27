import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';

/// Contrast check on the rendered pixels that is robust against
/// anti-aliasing.
///
/// Flutter's [textContrastGuideline] takes the most frequent non-background
/// colour of a node as the text colour. For small thin text that is an
/// anti-aliased edge pixel, a blend of text and background, so it reports
/// ratios far below the real one: "Noch keine Favoriten gespeichert." in the
/// muted token #898DA1 on #0F1221 (5.66:1) is reported as 3.97:1, and its
/// pixels do contain #898DA1 itself.
///
/// This guideline takes, for every labelled node, the most frequent colour in
/// its rectangle as background and the pixel that contrasts most with it as
/// foreground (fully covered glyph pixels have the true text colour). Faded
/// text (opacity, disabled style, overlay) and weak colour pairs still fail,
/// because then no pixel reaches the ratio.
class FullCoverageContrastGuideline extends AccessibilityGuideline {
  const FullCoverageContrastGuideline({this.minRatio = Contrast.aaText});

  final double minRatio;

  @override
  String get description =>
      'Rendered text reaches a contrast of $minRatio:1 (full-coverage pixels)';

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    late ui.Image image;
    late ByteData data;
    await tester.runAsync(() async {
      image = await layer.toImage(view.paintBounds);
      data = (await image.toByteData())!;
    });
    final width = image.width;
    final height = image.height;
    final failures = <String>[];

    void check(SemanticsNode node, Rect rect) {
      final x0 = rect.left.floor().clamp(0, width - 1);
      final x1 = rect.right.ceil().clamp(0, width);
      final y0 = rect.top.floor().clamp(0, height - 1);
      final y1 = rect.bottom.ceil().clamp(0, height);
      final counts = <int, int>{};
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final o = (y * width + x) * 4;
          final rgb =
              (data.getUint8(o) << 16) |
              (data.getUint8(o + 1) << 8) |
              data.getUint8(o + 2);
          counts[rgb] = (counts[rgb] ?? 0) + 1;
        }
      }
      if (counts.length < 2) return; // no glyphs rendered in the rectangle
      final bg = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final bgColor = Color(0xFF000000 | bg.key);
      var best = 0.0;
      for (final rgb in counts.keys) {
        final ratio = Contrast.ratio(Color(0xFF000000 | rgb), bgColor);
        if (ratio > best) best = ratio;
      }
      // Icon-only controls (at most 56 dp square) are graphical objects:
      // WCAG 1.4.11 asks 3:1 for them, text needs the full ratio.
      final iconOnly = rect.width <= 56 && rect.height <= 56;
      final required = iconOnly ? Contrast.aaLarge : minRatio;
      if (best < required) {
        failures.add(
          '"${node.label}" ${rect.size}: best ${best.toStringAsFixed(2)}:1 '
          'on #${bg.key.toRadixString(16)}',
        );
      }
    }

    void walk(SemanticsNode node, Matrix4 parent) {
      final m = Matrix4.copy(parent);
      if (node.transform != null) m.multiply(node.transform!);
      if (node.label.isNotEmpty &&
          !node.flagsCollection.isHidden &&
          node.rect.width > 4) {
        check(node, MatrixUtils.transformRect(m, node.rect));
      }
      node.visitChildren((child) {
        walk(child, m);
        return true;
      });
    }

    walk(view.owner!.semanticsOwner!.rootSemanticsNode!, Matrix4.identity());
    return failures.isEmpty
        ? const Evaluation.pass()
        : Evaluation.fail(failures.join('\n'));
  }
}
