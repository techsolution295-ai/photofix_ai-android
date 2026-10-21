import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/services/pro_purchase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pro_award_badge.dart';

/// Scales the paywall spacing so the same layout fits short and tall phones.
class _PaywallFit {
  _PaywallFit(double height, double width)
      : t = (height / 760).clamp(0.68, 1.14),
        narrow = width < 360;

  final double t;
  final bool narrow;

  double y(double base) => base * t;

  double get text => (0.9 + (t - 0.68) * 0.28).clamp(0.9, 1.05);

  double get horizontal => narrow ? 16 : 24;
  double get top => y(12);
  double get bottom => y(16);
  double get badge => y(84).clamp(52, 96);
  double get heroGap => y(12);
  double get afterHero => y(12);
  double get afterFeatures => y(14);
  double get afterFree => y(20);
  double get planGap => y(20);
  double get beforeFooter => y(28);
  double get afterButton => y(10);
  double get beforeLegal => y(18);
  double get footerBottom => y(10);
  double get planPadV => y(10).clamp(6, 12);
  double get titleSize => 24 * text;
  double get subtitleSize => 15 * text;
  double get buttonHeight => y(52).clamp(44, 56);
  double get featureGap => y(3).clamp(1, 4);
  double get featureIcon => y(20).clamp(16, 22);
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.openedFromSplash = false});

  final bool openedFromSplash;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const _plans = [
    _Plan(
      id: 'weekly',
      name: 'Weekly',
      period: 'Per week',
      subtitle: 'Flexible short-term access',
    ),
    _Plan(
      id: 'monthly',
      name: 'Monthly',
      period: 'Per month',
      subtitle: 'Full access, cancel anytime',
      badge: 'MOST POPULAR',
    ),
    _Plan(
      id: 'yearly',
      name: 'Yearly',
      period: 'Per year',
      subtitle: 'Best long-term value',
      badge: 'BEST VALUE',
    ),
  ];

  String _selectedId = 'monthly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProPurchaseService>().loadProducts();
    });
  }

  void _leaveFree() {
    if (widget.openedFromSplash || !Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacementNamed(RouteNames.main);
      return;
    }
    Navigator.of(context).pop();
  }

  void _openHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.main,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<SettingsProvider>().isPremium;
    final billing = context.watch<ProPurchaseService>();
    if (isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openHome();
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final plans = [
      for (final plan in _plans)
        _Plan(
          id: plan.id,
          name: plan.name,
          period: plan.period,
          subtitle: plan.subtitle,
          badge: plan.badge,
          priceLabel: billing.priceLabel(plan.id),
          price: billing.rawPrice(plan.id),
        ),
    ];
    final selected = plans.firstWhere((plan) => plan.id == _selectedId);
    final weekly = plans.first.price;
    final monthly = plans[1].price;
    final yearly = plans.last.price;
    final monthlySavings = _saveVersusWeekly(
      weekly: weekly,
      plan: monthly,
      weeks: 4,
    );
    final yearlySavings = _saveVersusWeekly(
      weekly: weekly,
      plan: yearly,
      weeks: 52,
    );

    return PopScope(
      canPop: !widget.openedFromSplash,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveFree();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fit =
                      _PaywallFit(constraints.maxHeight, constraints.maxWidth);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      fit.horizontal,
                      fit.top,
                      fit.horizontal,
                      fit.bottom,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.maxWidth - (fit.horizontal * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Hero(fit: fit),
                            SizedBox(height: fit.afterHero),
                            _FeatureComparison(fit: fit)
                                .animate()
                                .fadeIn(duration: 450.ms, delay: 180.ms)
                                .slideY(begin: 0.06, end: 0),
                            SizedBox(height: fit.afterFeatures),
                            _Plans(
                              plans: plans,
                              selectedId: _selectedId,
                              monthlySavings: monthlySavings,
                              yearlySavings: yearlySavings,
                              fit: fit,
                              onSelect: (id) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedId = id);
                              },
                              onContinueFree: _leaveFree,
                            ),
                            SizedBox(height: fit.beforeFooter),
                            _Footer(
                              priceLabel: selected.priceLabel,
                              planId: selected.id,
                              fit: fit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.fit});

  final _PaywallFit fit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProAwardBadge(size: fit.badge)
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.86, 0.86), curve: Curves.easeOutBack),
        SizedBox(height: fit.heroGap),
        Text(
          'START LIKE A PRO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fit.titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: AppColors.darkText,
            height: 1.15,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
        SizedBox(height: fit.y(4)),
        Text(
          'Unlock every photo tool',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fit.subtitleSize,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 140.ms),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({
    required this.plans,
    required this.selectedId,
    required this.monthlySavings,
    required this.yearlySavings,
    required this.fit,
    required this.onSelect,
    required this.onContinueFree,
  });

  final List<_Plan> plans;
  final String selectedId;
  final String? monthlySavings;
  final String? yearlySavings;
  final _PaywallFit fit;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinueFree;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: fit.afterFree),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onContinueFree();
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                'Continue with Free',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.secondaryText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        for (var i = 0; i < plans.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == plans.length - 1 ? 0 : fit.planGap,
            ),
            child: _PlanCard(
              plan: plans[i],
              selected: selectedId == plans[i].id,
              detail: switch (plans[i].id) {
                'monthly' => monthlySavings,
                'yearly' => yearlySavings,
                _ => null,
              },
              fit: fit,
              onTap: () => onSelect(plans[i].id),
            )
                .animate()
                .fadeIn(duration: 350.ms, delay: (220 + i * 80).ms)
                .slideY(begin: 0.08, end: 0),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.priceLabel,
    required this.planId,
    required this.fit,
  });

  final String priceLabel;
  final String planId;
  final _PaywallFit fit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: fit.footerBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContinueButton(
            height: fit.buttonHeight,
            label: 'Continue  ·  $priceLabel',
            onTap: () async {
              HapticFeedback.mediumImpact();
              final billing = context.read<ProPurchaseService>();
              final started = await billing.buy(planId);
              if (!context.mounted || started) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    billing.lastMessage ??
                        'Could not open checkout. Please try again.',
                  ),
                ),
              );
            },
          ),
          SizedBox(height: fit.afterButton),
          const Text(
            'Subscription auto-renews until canceled. Cancel anytime to avoid future charges.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: fit.beforeLegal),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _FooterLink(
                label: 'Privacy Policy',
                onTap: () => _open(AppConfig.privacyPolicyUrl),
              ),
              _FooterLink(
                label: 'Restore Purchases',
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await context.read<ProPurchaseService>().restore();
                  if (!context.mounted) return;
                  final isPremium = context.read<SettingsProvider>().isPremium;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPremium
                            ? 'Pro access restored.'
                            : 'No active subscription was found.',
                      ),
                    ),
                  );
                },
              ),
              _FooterLink(
                label: 'Terms of Use',
                onTap: () => _open(AppConfig.termsUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.label,
    required this.onTap,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmer, _pulse]),
      builder: (context, child) {
        final travel = _shimmer.value;
        final scale = _pressed ? 0.97 : _scale.value;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    splashColor: Colors.white.withValues(alpha: 0.16),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FractionallySizedBox(
                              widthFactor: 0.45,
                              alignment: Alignment(-1.4 + (travel * 2.8), 0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.22),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: child!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Text(
          widget.label,
          key: ValueKey(widget.label),
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FeatureComparison extends StatelessWidget {
  const _FeatureComparison({required this.fit});

  final _PaywallFit fit;

  static const _features = [
    _Feature(
      icon: Icons.auto_fix_high_rounded,
      title: 'AI Enhance',
      basic: true,
    ),
    _Feature(
      icon: Icons.crop_rounded,
      title: 'Crop & Filters',
      basic: true,
    ),
    _Feature(
      icon: Icons.hd_rounded,
      title: 'Unlimited HD Upscale',
      basic: false,
    ),
    _Feature(
      icon: Icons.headset_mic_outlined,
      title: 'VIP Support',
      basic: false,
    ),
    _Feature(icon: Icons.block_rounded, title: 'Remove Ads', basic: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(child: SizedBox()),
              SizedBox(
                width: 72,
                child: Text(
                  'PREMIUM',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.darkText,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'BASIC',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.darkText,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final feature in _features)
          Padding(
            padding: EdgeInsets.only(bottom: fit.featureGap),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Center(
                    child: _GradientIcon(
                      icon: feature.icon,
                      size: fit.featureIcon,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 13.5 * fit.text,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 72,
                  child: Center(child: _StatusMark(enabled: true)),
                ),
                SizedBox(
                  width: 56,
                  child: Center(child: _StatusMark(enabled: feature.basic)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return const _GradientIcon(icon: Icons.check_rounded, size: 26);
    }
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
      child: Container(
        width: 16,
        height: 3.2,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.detail,
    required this.fit,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final String? detail;
  final _PaywallFit fit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: fit.planPadV,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dividerLight,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? AppColors.primaryGradient : null,
                  border: selected
                      ? null
                      : Border.all(color: AppColors.dividerLight, width: 1.6),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (plan.badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        detail ?? plan.subtitle,
                        style: TextStyle(
                          color: detail != null
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: detail != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.period,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _saveVersusWeekly({
  required double? weekly,
  required double? plan,
  required int weeks,
}) {
  if (weekly == null || plan == null || weekly <= 0) return null;
  final percent = (1 - (plan / (weekly * weeks))) * 100;
  if (percent <= 0) return null;
  return 'Save ${percent.round()}% vs weekly';
}

class _Plan {
  const _Plan({
    required this.id,
    required this.name,
    required this.period,
    required this.subtitle,
    this.priceLabel = '__',
    this.price,
    this.badge,
  });

  final String id;
  final String name;
  final String period;
  final String subtitle;
  final String? badge;
  final String priceLabel;
  final double? price;
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.basic,
  });

  final IconData icon;
  final String title;
  final bool basic;
}
