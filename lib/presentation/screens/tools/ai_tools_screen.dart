import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/route_names.dart';

/// Tools tab — matches product design (sections + Free badge + hero).
class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  static const _creative = <_ToolDef>[
    _ToolDef(
      'AI Cartoon',
      'Turn photos into amazing cartoons',
      Icons.auto_awesome_rounded,
      Color(0xFF7B5CFF),
      Color(0xFFEEE8FF),
      RouteNames.cartoon,
    ),
    _ToolDef(
      'AI Portrait',
      'Create studio quality portraits',
      Icons.face_retouching_natural_rounded,
      Color(0xFFE84D8A),
      Color(0xFFFFEAF2),
      RouteNames.portrait,
    ),
    _ToolDef(
      'Background Changer',
      'Change photo background',
      Icons.person_search_rounded,
      Color(0xFF3B82F6),
      Color(0xFFE8F0FF),
      RouteNames.backgroundChanger,
    ),
  ];

  static const _fun = <_ToolDef>[
    _ToolDef(
      'Stickers & Text',
      'Add stickers, text and more',
      Icons.emoji_emotions_rounded,
      Color(0xFFF59E0B),
      Color(0xFFFFF4E0),
      RouteNames.stickersText,
    ),
    _ToolDef(
      'Age Changer',
      'See your future or past look',
      Icons.elderly_rounded,
      Color(0xFF8B5CF6),
      Color(0xFFF0EAFF),
      RouteNames.ageChanger,
    ),
    _ToolDef(
      'Art Styles',
      'Oil painting, sketch and more',
      Icons.brush_rounded,
      Color(0xFFEC4899),
      Color(0xFFFFEAF4),
      RouteNames.artStyles,
    ),
  ];

  static const _effects = <_ToolDef>[
    _ToolDef(
      'Filters',
      'Apply beautiful filters',
      Icons.palette_rounded,
      Color(0xFFF97316),
      Color(0xFFFFF0E6),
      RouteNames.filters,
    ),
    _ToolDef(
      'Collage Maker',
      'Create stunning photo collages',
      Icons.grid_view_rounded,
      Color(0xFF6366F1),
      Color(0xFFEEF0FF),
      RouteNames.collage,
    ),
    _ToolDef(
      'Format Convert',
      'JPG, PNG & more',
      Icons.image_outlined,
      Color(0xFF14B8A6),
      Color(0xFFE6FBF8),
      RouteNames.formatConvert,
    ),
  ];

  static const _utility = <_ToolDef>[
    _ToolDef(
      'Crop',
      'Crop your photo',
      Icons.crop_rounded,
      Color(0xFF7C5CFF),
      Color(0xFFEEE8FF),
      RouteNames.crop,
    ),
    _ToolDef(
      'Rotate',
      'Rotate any photo',
      Icons.rotate_right_rounded,
      Color(0xFF7C5CFF),
      Color(0xFFEEE8FF),
      RouteNames.rotate,
    ),
    _ToolDef(
      'Compress',
      'Reduce file size',
      Icons.compress_rounded,
      Color(0xFF7C5CFF),
      Color(0xFFEEE8FF),
      RouteNames.compress,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _HeroBanner(),
              ),
            ),
            SliverToBoxAdapter(
                child: _Section(title: 'Creative Tools', tools: _creative)),
            SliverToBoxAdapter(
                child: _Section(title: 'Fun & Creative', tools: _fun)),
            SliverToBoxAdapter(
                child: _Section(title: 'Effects', tools: _effects)),
            SliverToBoxAdapter(
                child: _Section(title: 'Utility Tools', tools: _utility)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            'AI Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final titleSize = (w * 0.048).clamp(16.0, 19.5);
        final bodySize = (w * 0.031).clamp(10.8, 12.0);

        return Container(
          height: 146,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment(-1.0, -0.55),
              end: Alignment(1.0, 0.75),
              colors: [
                Color(0xFF4B1FD6),
                Color(0xFF5B3DF5),
                Color(0xFF4568FF),
              ],
              stops: [0.0, 0.48, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3DF5).withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -36,
                  child: _GlowBlob(
                    size: 118,
                    color: const Color(0xFF8B7CFF).withValues(alpha: 0.34),
                  ),
                ),
                Positioned(
                  right: 36,
                  bottom: -48,
                  child: _GlowBlob(
                    size: 108,
                    color: const Color(0xFF3D9CFF).withValues(alpha: 0.22),
                  ),
                ),
                Positioned(
                  left: 96,
                  top: 10,
                  child: CustomPaint(
                    size: const Size(9, 9),
                    painter: _StarPainter(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                Positioned(
                  left: 168,
                  bottom: 16,
                  child: CustomPaint(
                    size: const Size(6, 6),
                    painter: _StarPainter(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 4, 15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Powerful AI.\nEndless Possibilities.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                height: 1.18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Text(
                                'Use advanced AI tools to edit, improve and transform your photos like magic.',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: bodySize,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: CustomPaint(
                          painter: _MagicArtPainter(),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MagicArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.52;
    final cy = size.height * 0.52;

    _drawGlassPane(
      canvas,
      center: Offset(cx + 10, cy + 6),
      side: size.width * 0.52,
      color: const Color(0xFF2EC4B6),
      alpha: 0.55,
      tilt: -0.18,
    );
    _drawGlassPane(
      canvas,
      center: Offset(cx + 2, cy + 1),
      side: size.width * 0.52,
      color: const Color(0xFF4C6FFF),
      alpha: 0.62,
      tilt: -0.12,
    );
    _drawGlassPane(
      canvas,
      center: Offset(cx - 6, cy - 4),
      side: size.width * 0.52,
      color: const Color(0xFFB8A6FF),
      alpha: 0.78,
      tilt: -0.06,
    );

    _drawWand(canvas, size);

    _drawSpark(
        canvas, Offset(cx - 18, cy - 28), size.width * 0.07, const Color(0xFFFFD84D));
    _drawSpark(
        canvas, Offset(cx + 8, cy - 34), size.width * 0.055, const Color(0xFFFFE27A));
    _drawSpark(
        canvas, Offset(cx + 22, cy - 12), size.width * 0.045, const Color(0xFFFFD84D));
    _drawSpark(
        canvas, Offset(cx - 2, cy + 10), size.width * 0.035, const Color(0xFFFFE9A0));
  }

  void _drawGlassPane(
    Canvas canvas, {
    required Offset center,
    required double side,
    required Color color,
    required double alpha,
    required double tilt,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);

    final rect =
        Rect.fromCenter(center: Offset.zero, width: side, height: side);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(side * 0.18));

    canvas.drawRRect(
      rrect.shift(const Offset(3, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.65),
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    final shineRect =
        Rect.fromLTWH(-side * 0.42, -side * 0.42, side * 0.84, side * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shineRect, Radius.circular(side * 0.12)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(shineRect),
    );

    canvas.restore();
  }

  void _drawWand(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.18, size.height * 0.78);
    final end = Offset(size.width * 0.78, size.height * 0.18);
    final dir = end - start;
    final len = dir.distance;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);

    final shadowPath = Path()
      ..moveTo((start + normal * 3).dx, (start + normal * 3).dy + 4)
      ..lineTo((end + normal * 2).dx, (end + normal * 2).dy + 4)
      ..lineTo((end - normal * 2).dx, (end - normal * 2).dy + 4)
      ..lineTo((start - normal * 3).dx, (start - normal * 3).dy + 4)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final handleEnd = start + unit * (len * 0.28);
    _drawSegment(
      canvas,
      start,
      handleEnd,
      widthStart: 7,
      widthEnd: 5.5,
      colors: const [Color(0xFFE8ECF4), Color(0xFF9AA3B5), Color(0xFFF2F5FA)],
    );

    final tipEnd = start + unit * (len * 0.82);
    _drawSegment(
      canvas,
      handleEnd,
      tipEnd,
      widthStart: 5.2,
      widthEnd: 4.2,
      colors: const [Color(0xFF8B6CFF), Color(0xFF5B3DF5), Color(0xFF9B82FF)],
    );

    _drawSegment(
      canvas,
      tipEnd,
      end,
      widthStart: 4.2,
      widthEnd: 3.2,
      colors: const [Color(0xFFFFFFFF), Color(0xFFE8E8F0), Color(0xFFFFFFFF)],
    );

    canvas.drawCircle(
      end,
      7,
      Paint()
        ..color = const Color(0xFFFFE27A).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(end, 3.2, Paint()..color = Colors.white);
  }

  void _drawSegment(
    Canvas canvas,
    Offset a,
    Offset b, {
    required double widthStart,
    required double widthEnd,
    required List<Color> colors,
  }) {
    final dir = b - a;
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    final n = Offset(-unit.dy, unit.dx);

    final path = Path()
      ..moveTo((a + n * widthStart / 2).dx, (a + n * widthStart / 2).dy)
      ..lineTo((b + n * widthEnd / 2).dx, (b + n * widthEnd / 2).dy)
      ..lineTo((b - n * widthEnd / 2).dx, (b - n * widthEnd / 2).dy)
      ..lineTo((a - n * widthStart / 2).dx, (a - n * widthStart / 2).dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
        ).createShader(Rect.fromPoints(a - n * 8, b + n * 8)),
    );
  }

  void _drawSpark(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a1 = (i * 90 - 90) * math.pi / 180;
      final a2 = (i * 90 - 45) * math.pi / 180;
      final p1 = Offset(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1));
      final p2 = Offset(
          c.dx + r * 0.32 * math.cos(a2), c.dy + r * 0.32 * math.sin(a2));
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a1 = (i * 90 - 90) * math.pi / 180;
      final a2 = (i * 90 - 45) * math.pi / 180;
      final p1 = Offset(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1));
      final p2 =
          Offset(c.dx + r * 0.3 * math.cos(a2), c.dy + r * 0.3 * math.sin(a2));
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tools});
  final String title;
  final List<_ToolDef> tools;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 10.0;
              final cardW = (c.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tools
                    .map((t) => SizedBox(
                          width: cardW,
                          child: _ToolCard(tool: t),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final _ToolDef tool;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(tool.route),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEEF0F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tool.softBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(tool.icon, color: tool.accent, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  tool.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tool.desc,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: Color(0xFF8B90A5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolDef {
  const _ToolDef(
    this.title,
    this.desc,
    this.icon,
    this.accent,
    this.softBg,
    this.route,
  );
  final String title;
  final String desc;
  final IconData icon;
  final Color accent;
  final Color softBg;
  final String route;
}
