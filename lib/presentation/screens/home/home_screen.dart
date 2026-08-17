import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';

/// Scrollable home — flexible layout like Tools screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenTools});

  final VoidCallback? onOpenTools;

  Future<void> _pick(BuildContext context, {required bool camera}) async {
    final picker = context.read<PhotoPickerService>();
    final analytics = context.read<AnalyticsService>();
    try {
      final file =
          camera ? await picker.takePhoto() : await picker.pickFromGallery();
      if (file == null || !context.mounted) return;
      await analytics.logEvent(AnalyticsEvents.photoSelected, {
        'source': camera ? 'camera' : 'gallery',
      });
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(
        RouteNames.enhance,
        arguments: ToolScreenArgs(initialImagePath: file.path),
      );
    } on AiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'camera_permanently_denied') {
        await openAppSettings();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FC),
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Header(),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _HeroCard(
                            onChoose: () => _pick(context, camera: false),
                            onCamera: () => _pick(context, camera: true),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _ToolsHeader(onSeeAll: onOpenTools),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.48,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ToolCard(
                        tool: _ToolsGrid.tools[i],
                        delayMs: 60 * i,
                      ),
                      childCount: _ToolsGrid.tools.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ambient background ───────────────────────────────────────

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF3F0FF),
                    Color(0xFFF6F8FF),
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(
              size: 180,
              color: const Color(0xFF6C4CF1).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: _Blob(
              size: 160,
              color: const Color(0xFF2677FF).withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: _Blob(
              size: 140,
              color: const Color(0xFF0D9488).withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C5CFF), Color(0xFF2F7BFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4CF1).withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/icon/app_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.auto_fix_high_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'PhotoFix ',
                    style: TextStyle(
                      color: Color(0xFF151827),
                      fontWeight: FontWeight.w800,
                      fontSize: 17.5,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      color: Color(0xFF6C4CF1),
                      fontWeight: FontWeight.w800,
                      fontSize: 17.5,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Enhance · Restore · Upscale',
              style: TextStyle(
                color: Color(0xFF8B90A5),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onChoose, required this.onCamera});
  final VoidCallback onChoose;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Opacity(
        opacity: ((scale - 0.96) / 0.04).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8EEFF),
              Color(0xFFF0EAFF),
              Color(0xFFF8F5FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFD9DFF5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C4CF1).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: _Blob(
                  size: 110,
                  color: const Color(0xFF6C4CF1).withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -40,
                child: _Blob(
                  size: 100,
                  color: const Color(0xFF2677FF).withValues(alpha: 0.10),
                ),
              ),
              LayoutBuilder(
                builder: (context, c) {
                  // Fixed-height hero — always use compact stack to avoid overflow.
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFD9DFF5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 11,
                                      color: Color(0xFF6C4CF1),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'On-device AI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5A5F78),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF151827),
                                    letterSpacing: -0.3,
                                  ),
                                  children: [
                                    TextSpan(text: 'Make Your Photos\nLook '),
                                    TextSpan(
                                      text: 'Amazing',
                                      style: TextStyle(
                                        color: Color(0xFF6C4CF1),
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              _PrimaryBtn(
                                title: 'Choose Photo',
                                subtitle: 'From Gallery',
                                icon: Icons.photo_library_rounded,
                                onTap: onChoose,
                                compact: true,
                              ),
                              const SizedBox(height: 6),
                              _SecondaryBtn(
                                title: 'Take Photo',
                                subtitle: 'Use Camera',
                                icon: Icons.photo_camera_outlined,
                                onTap: onCamera,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(flex: 11, child: _BeforeAfter()),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4CF1), Color(0xFF3B82F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4CF1).withValues(alpha: 0.32),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: compact ? 7 : 9,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 26 : 28,
                  height: compact ? 26 : 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 12 : 12.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
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

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE0E5F2)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 26 : 28,
                height: compact ? 26 : 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: const Color(0xFF1A1D2E), size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF1A1D2E),
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 12.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8B90A5),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeforeAfter extends StatefulWidget {
  const _BeforeAfter();

  @override
  State<_BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<_BeforeAfter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/hero_landscape.png', fit: BoxFit.cover),
            ClipRect(
              clipper: const _HalfClipper(0.48),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset(
                  'assets/images/hero_landscape.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Align(
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_pulse.value);
                  return Transform.scale(
                    scale: 1 + (t * 0.06),
                    child: child,
                  );
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    size: 15,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
              ),
            ),
            Positioned(left: 8, top: 8, child: _tag('Before')),
            Positioned(right: 8, top: 8, child: _tag('After')),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: Colors.black.withValues(alpha: 0.42),
            child: Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper(this.ratio);
  final double ratio;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * ratio, size.height);

  @override
  bool shouldReclip(covariant _HalfClipper old) => old.ratio != ratio;
}

// ─── Tools ────────────────────────────────────────────────────

class _ToolsHeader extends StatelessWidget {
  const _ToolsHeader({this.onSeeAll});
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Tools',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF151827),
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pick a tool to start',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8B90A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        Material(
          color: const Color(0xFFEEE9FF),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF6C4CF1),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF6C4CF1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolsGrid {
  static const tools = <_Tool>[
    _Tool(
      'AI Enhance',
      'Quality & lighting',
      Icons.auto_fix_high_rounded,
      Color(0xFF6C4CF1),
      Color(0xFFEEE8FF),
      RouteNames.enhance,
    ),
    _Tool(
      'AI Upscale',
      'Up to 4X HD',
      Icons.hd_rounded,
      Color(0xFF2677FF),
      Color(0xFFE7F0FF),
      RouteNames.upscale,
    ),
    _Tool(
      'Restore',
      'Fix old photos',
      Icons.photo_filter_rounded,
      Color(0xFF16A34A),
      Color(0xFFE7F8EE),
      RouteNames.restore,
    ),
    _Tool(
      'Colorize',
      'B&W to color',
      Icons.palette_rounded,
      Color(0xFFEA7A2F),
      Color(0xFFFFF0E6),
      RouteNames.colorize,
    ),
    _Tool(
      'Denoise',
      'Clean grain',
      Icons.blur_on_rounded,
      Color(0xFFE11D78),
      Color(0xFFFFEAF2),
      RouteNames.denoise,
    ),
    _Tool(
      'Sharpen',
      'Crisp details',
      Icons.center_focus_strong_rounded,
      Color(0xFF0D9488),
      Color(0xFFE6FBF8),
      RouteNames.sharpen,
    ),
  ];
}

class _Tool {
  const _Tool(
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

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    this.delayMs = 0,
  });
  final _Tool tool;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    const iconSize = 34.0;
    const pad = 12.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, tool.route),
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEF0F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: tool.softBg,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: tool.accent.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          tool.icon,
                          color: tool.accent,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tool.accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: tool.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tool.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.1,
                      color: const Color(0xFF151827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      tool.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: Color(0xFF8B90A5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
