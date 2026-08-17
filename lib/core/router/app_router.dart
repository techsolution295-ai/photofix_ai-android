import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/screens/legal/legal_screens.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/tools/crop_editor_screen.dart';
import '../../presentation/screens/tools/tool_screens.dart';
import '../../presentation/screens/tools/utility_tools_screen.dart';
import '../constants/route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case RouteNames.splash:
        return _fade(const SplashScreen());
      case RouteNames.main:
        return _crossFade(const MainShell());
      case RouteNames.enhance:
        return _slide(EnhanceScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.upscale:
        return _slide(UpscaleScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.restore:
        return _slide(RestoreScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.colorize:
        return _slide(ColorizeScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.denoise:
        return _slide(DenoiseScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.sharpen:
        return _slide(SharpenScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.cartoon:
        return _slide(CartoonScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.portrait:
        return _slide(PortraitScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.backgroundChanger:
        return _slide(BackgroundChangerScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.stickersText:
        return _slide(StickersTextScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.ageChanger:
        return _slide(AgeChangerScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.artStyles:
        return _slide(ArtStylesScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.filters:
        return _slide(FiltersScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.collage:
        return _slide(CollageScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.crop:
        return _slide(CropScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.rotate:
        return _slide(RotateScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.compress:
        return _slide(CompressScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.formatConvert:
        return _slide(FormatConvertScreen(args: args is ToolScreenArgs ? args : null));
      case RouteNames.result:
        if (args is ResultArgs) {
          return _slide(ResultScreen(args: args));
        }
        return _fade(const Scaffold(
          body: Center(child: Text('Missing result data')),
        ));
      case RouteNames.history:
        return _slide(const HistoryScreen());
      case RouteNames.settings:
        return _slide(const SettingsScreen());
      case RouteNames.privacy:
        return _slide(const PrivacyScreen());
      case RouteNames.terms:
        return _slide(const TermsScreen());
      case RouteNames.help:
        return _slide(const HelpFaqScreen());
      default:
        return _fade(const Scaffold(
          body: Center(child: Text('Route not found')),
        ));
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Smooth splash → home without a white flash.
  /// Keeps the previous route visible underneath while the next fades in.
  static PageRouteBuilder<dynamic> _crossFade(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => child,
      opaque: false,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  static PageRouteBuilder<dynamic> _slide(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: offset, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
