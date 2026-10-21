import 'package:flutter/material.dart';

/// Release builds tree-shake the Material icon font.
/// These const icons stay in the APK so tool and nav icons still draw.
class ReleaseIconFont extends StatelessWidget {
  const ReleaseIconFont({super.key});

  @override
  Widget build(BuildContext context) {
    return const Offstage(
      child: Wrap(
        children: [
          Icon(Icons.home_rounded),
          Icon(Icons.home_outlined),
          Icon(Icons.grid_view_rounded),
          Icon(Icons.history_rounded),
          Icon(Icons.history),
          Icon(Icons.settings_rounded),
          Icon(Icons.settings_outlined),
          Icon(Icons.help_outline),
          Icon(Icons.auto_fix_high_rounded),
          Icon(Icons.auto_awesome_rounded),
          Icon(Icons.hd_rounded),
          Icon(Icons.photo_filter_rounded),
          Icon(Icons.palette_rounded),
          Icon(Icons.blur_on_rounded),
          Icon(Icons.center_focus_strong_rounded),
          Icon(Icons.photo_library_rounded),
          Icon(Icons.photo_library_outlined),
          Icon(Icons.photo_camera_rounded),
          Icon(Icons.photo_camera_outlined),
          Icon(Icons.photo_outlined),
          Icon(Icons.add_photo_alternate_rounded),
          Icon(Icons.add_photo_alternate_outlined),
          Icon(Icons.compare_arrows_rounded),
          Icon(Icons.compare_arrows),
          Icon(Icons.chevron_right_rounded),
          Icon(Icons.arrow_forward_rounded),
          Icon(Icons.arrow_back_rounded),
          Icon(Icons.swap_horiz_rounded),
          Icon(Icons.face_retouching_natural_rounded),
          Icon(Icons.person_search_rounded),
          Icon(Icons.emoji_emotions_rounded),
          Icon(Icons.elderly_rounded),
          Icon(Icons.brush_rounded),
          Icon(Icons.image_outlined),
          Icon(Icons.crop_rounded),
          Icon(Icons.rotate_right_rounded),
          Icon(Icons.rotate_left_rounded),
          Icon(Icons.flip_rounded),
          Icon(Icons.compress_rounded),
          Icon(Icons.check_rounded),
          Icon(Icons.close_rounded),
          Icon(Icons.download_rounded),
          Icon(Icons.download),
          Icon(Icons.more_vert_rounded),
          Icon(Icons.filter_list_off_rounded),
          Icon(Icons.broken_image_outlined),
          Icon(Icons.error_outline),
          Icon(Icons.privacy_tip_outlined),
          Icon(Icons.description_outlined),
          Icon(Icons.support_agent_rounded),
          Icon(Icons.person),
          Icon(Icons.mail_outline),
          Icon(Icons.star_outline),
          Icon(Icons.star_rounded),
          Icon(Icons.workspace_premium_rounded),
          Icon(Icons.headset_mic_outlined),
          Icon(Icons.block_rounded),
        ],
      ),
    );
  }
}
