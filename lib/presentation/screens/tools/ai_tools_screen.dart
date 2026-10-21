import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../navigation/open_tool.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/pro_chip.dart';

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
            const SliverToBoxAdapter(child: _ToolsHeader()),
            const SliverToBoxAdapter(child: BannerAdWidget()),
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

class _ToolsHeader extends StatelessWidget {
  const _ToolsHeader();

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SettingsProvider>().isPremium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'AI Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D2E),
                letterSpacing: -0.3,
              ),
            ),
            if (!isPro)
              const Align(
                alignment: Alignment.centerRight,
                child: ProChip(),
              ),
          ],
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
          height: 112,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 12,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
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
                            const SizedBox(height: 4),
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
                      ),
                      Expanded(
                        flex: 9,
                        child: Image.asset(
                          'assets/images/tools_hero_wand.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
        onTap: () => openTool(context, tool.route),
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
