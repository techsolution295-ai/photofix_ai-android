import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ai_models.dart';
import '../../../domain/models/models.dart';
import '../process/tool_process_screen.dart';

/// Single-row professional option pills (selected / unselected).
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  final List<(String id, String label)> items;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _OptionPill(
                label: items[i].$2,
                selected: selectedId == items[i].$1,
                onTap: () => onChanged(items[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : const Color(0xFFF3F4F8),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE4E7F0),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: selected ? Colors.white : const Color(0xFF5A6078),
            ),
          ),
        ),
      ),
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class EnhanceScreen extends StatefulWidget {
  const EnhanceScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  EnhanceStrength _strength = EnhanceStrength.strong;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: AppStrings.enhance,
      description: AppStrings.enhanceDesc,
      operation: AiOperation.enhance,
      actionLabel: 'Enhance Photo',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _strength.name,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, setOuter) {
        return _OptionRow(
          items:
              EnhanceStrength.values.map((s) => (s.name, _cap(s.name))).toList(),
          selectedId: _strength.name,
          onChanged: (id) => setState(
            () => _strength =
                EnhanceStrength.values.firstWhere((e) => e.name == id),
          ),
        );
      },
    );
  }
}

class UpscaleScreen extends StatefulWidget {
  const UpscaleScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<UpscaleScreen> createState() => _UpscaleScreenState();
}

class _UpscaleScreenState extends State<UpscaleScreen> {
  UpscaleFactor _factor = UpscaleFactor.x2;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: AppStrings.upscale,
      description: AppStrings.upscaleDesc,
      operation: AiOperation.upscale,
      actionLabel: 'Upscale Photo',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: null,
        upscaleFactor: _factor.value,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, setOuter) {
        return _OptionRow(
          items: const [('2', '2X'), ('4', '4X')],
          selectedId: _factor == UpscaleFactor.x2 ? '2' : '4',
          onChanged: (id) => setState(
            () => _factor = id == '4' ? UpscaleFactor.x4 : UpscaleFactor.x2,
          ),
        );
      },
    );
  }
}

class RestoreScreen extends StatelessWidget {
  const RestoreScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: AppStrings.restore,
      description: AppStrings.restoreDesc,
      operation: AiOperation.restore,
      actionLabel: 'Restore Photo',
      initialImagePath: args?.initialImagePath,
      resolveParams: () => (
        strength: null,
        upscaleFactor: null,
        options: <String, dynamic>{
          'remove_scratches': true,
          'improve_faces': true,
          'reduce_blur': true,
          'improve_contrast': true,
        },
      ),
    );
  }
}

class ColorizeScreen extends StatelessWidget {
  const ColorizeScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'AI Colorize',
      description: AppStrings.colorizeDesc,
      operation: AiOperation.colorize,
      actionLabel: 'Colorize Photo',
      initialImagePath: args?.initialImagePath,
    );
  }
}

class DenoiseScreen extends StatefulWidget {
  const DenoiseScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<DenoiseScreen> createState() => _DenoiseScreenState();
}

class _DenoiseScreenState extends State<DenoiseScreen> {
  DenoiseStrength _strength = DenoiseStrength.medium;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: AppStrings.denoise,
      description: AppStrings.denoiseDesc,
      operation: AiOperation.denoise,
      actionLabel: 'Remove Noise',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _strength.name,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items:
              DenoiseStrength.values.map((s) => (s.name, _cap(s.name))).toList(),
          selectedId: _strength.name,
          onChanged: (id) => setState(
            () => _strength =
                DenoiseStrength.values.firstWhere((e) => e.name == id),
          ),
        );
      },
    );
  }
}

class SharpenScreen extends StatefulWidget {
  const SharpenScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<SharpenScreen> createState() => _SharpenScreenState();
}

class _SharpenScreenState extends State<SharpenScreen> {
  SharpenStrength _strength = SharpenStrength.medium;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: AppStrings.sharpen,
      description: AppStrings.sharpenDesc,
      operation: AiOperation.sharpen,
      actionLabel: 'Sharpen Photo',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _strength.name,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items:
              SharpenStrength.values.map((s) => (s.name, _cap(s.name))).toList(),
          selectedId: _strength.name,
          onChanged: (id) => setState(
            () => _strength =
                SharpenStrength.values.firstWhere((e) => e.name == id),
          ),
        );
      },
    );
  }
}

class CartoonScreen extends StatefulWidget {
  const CartoonScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<CartoonScreen> createState() => _CartoonScreenState();
}

class _CartoonScreenState extends State<CartoonScreen> {
  String _style = 'soft';

  static const _styles = <(String, String)>[
    ('soft', 'Soft'),
    ('classic', 'Classic'),
    ('bold', 'Bold'),
    ('pop', 'Pop'),
  ];

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'AI Cartoon',
      description:
          'Smooth illustration look — soft colors, light outlines, no harsh black blobs.',
      operation: AiOperation.cartoon,
      actionLabel: 'Apply Cartoon',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _style,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items: _styles,
          selectedId: _style,
          onChanged: (id) => setState(() => _style = id),
        );
      },
    );
  }
}

class PortraitScreen extends StatelessWidget {
  const PortraitScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'AI Portrait',
      description: 'Create studio quality portraits',
      operation: AiOperation.portrait,
      actionLabel: 'Apply Portrait',
      initialImagePath: args?.initialImagePath,
    );
  }
}

class BackgroundChangerScreen extends StatefulWidget {
  const BackgroundChangerScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<BackgroundChangerScreen> createState() =>
      _BackgroundChangerScreenState();
}

class _BackgroundChangerScreenState extends State<BackgroundChangerScreen> {
  String _bg = 'blue';

  static const _colors = <(String, String, Color)>[
    ('white', 'White', Color(0xFFF5F6FA)),
    ('black', 'Black', Color(0xFF1C1E24)),
    ('gray', 'Gray', Color(0xFFD2D6DE)),
    ('charcoal', 'Charcoal', Color(0xFF484E5A)),
    ('beige', 'Beige', Color(0xFFECE0CE)),
    ('cream', 'Cream', Color(0xFFFFF8E6)),
    ('brown', 'Brown', Color(0xFF8C6246)),
    ('red', 'Red', Color(0xFFE64646)),
    ('coral', 'Coral', Color(0xFFFF7F6E)),
    ('orange', 'Orange', Color(0xFFFF9846)),
    ('yellow', 'Yellow', Color(0xFFFFD650)),
    ('lime', 'Lime', Color(0xFFAADC5A)),
    ('green', 'Green', Color(0xFF5ABE82)),
    ('mint', 'Mint', Color(0xFFA0E6D2)),
    ('teal', 'Teal', Color(0xFF32AFAA)),
    ('cyan', 'Cyan', Color(0xFF5AD2EB)),
    ('sky', 'Sky', Color(0xFF96C8FF)),
    ('blue', 'Blue', Color(0xFF7896FF)),
    ('navy', 'Navy', Color(0xFF28468C)),
    ('indigo', 'Indigo', Color(0xFF5A5AC8)),
    ('purple', 'Purple', Color(0xFFA06EE6)),
    ('lavender', 'Lavender', Color(0xFFD2BEFF)),
    ('pink', 'Pink', Color(0xFFFFB6D2)),
    ('magenta', 'Magenta', Color(0xFFE650AA)),
    ('maroon', 'Maroon', Color(0xFF8C2D46)),
    ('gold', 'Gold', Color(0xFFE6BE64)),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _colors.firstWhere(
      (c) => c.$1 == _bg,
      orElse: () => _colors.first,
    );

    return ToolProcessScreen(
      title: 'Background Changer',
      description: 'Pick any studio background color for your photo.',
      operation: AiOperation.backgroundChanger,
      actionLabel: 'Change Background',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _bg,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Color',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF8B90A5),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: selected.$3,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD0D4E0)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  selected.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final c = _colors[i];
                  final active = _bg == c.$1;
                  final isLight = c.$3.computeLuminance() > 0.78;
                  return GestureDetector(
                    onTap: () => setState(() => _bg = c.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.$3,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFD8DCE8),
                          width: active ? 2.5 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: active
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: isLight
                                  ? const Color(0xFF1A1D2E)
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class AgeChangerScreen extends StatefulWidget {
  const AgeChangerScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<AgeChangerScreen> createState() => _AgeChangerScreenState();
}

class _AgeChangerScreenState extends State<AgeChangerScreen> {
  String _mode = 'older';

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'Age Changer',
      description: 'See your future or past look',
      operation: AiOperation.ageChanger,
      actionLabel: 'Apply Age Look',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _mode,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items: const [('younger', 'Younger'), ('older', 'Older')],
          selectedId: _mode,
          onChanged: (id) => setState(() => _mode = id),
        );
      },
    );
  }
}

class ArtStylesScreen extends StatefulWidget {
  const ArtStylesScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<ArtStylesScreen> createState() => _ArtStylesScreenState();
}

class _ArtStylesScreenState extends State<ArtStylesScreen> {
  String _style = 'oil';

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'Art Styles',
      description: 'Convert to oil painting, sketch and more',
      operation: AiOperation.artStyles,
      actionLabel: 'Apply Art Style',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _style,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items: const [('oil', 'Oil'), ('sketch', 'Sketch'), ('pop', 'Pop')],
          selectedId: _style,
          onChanged: (id) => setState(() => _style = id),
        );
      },
    );
  }
}

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, this.args});
  final ToolScreenArgs? args;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  String _preset = 'vivid';

  @override
  Widget build(BuildContext context) {
    return ToolProcessScreen(
      title: 'Filters',
      description: 'Apply beautiful filters',
      operation: AiOperation.filters,
      actionLabel: 'Apply Filter',
      initialImagePath: widget.args?.initialImagePath,
      resolveParams: () => (
        strength: _preset,
        upscaleFactor: null,
        options: <String, dynamic>{},
      ),
      optionsBuilder: (context, _) {
        return _OptionRow(
          items: const [
            ('vivid', 'Vivid'),
            ('warm', 'Warm'),
            ('cool', 'Cool'),
            ('mono', 'Mono'),
          ],
          selectedId: _preset,
          onChanged: (id) => setState(() => _preset = id),
        );
      },
    );
  }
}
