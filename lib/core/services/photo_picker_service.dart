import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/ai_models.dart';
import '../config/app_config.dart';
import '../constants/app_strings.dart';

class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _supported = {'.jpg', '.jpeg', '.png', '.webp'};

  Future<File?> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: AppConfig.maxImageDimension.toDouble(),
      maxHeight: AppConfig.maxImageDimension.toDouble(),
      requestFullMetadata: false,
    );
    if (x == null) return null;
    return validate(File(x.path));
  }

  Future<File?> takePhoto() async {
    final cam = await Permission.camera.request();
    if (cam.isPermanentlyDenied) {
      throw AiException(
        AppStrings.cameraPermission,
        code: 'camera_permanently_denied',
      );
    }
    if (!cam.isGranted) {
      throw AiException(AppStrings.cameraPermission, code: 'camera_denied');
    }

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
      maxWidth: AppConfig.maxImageDimension.toDouble(),
      maxHeight: AppConfig.maxImageDimension.toDouble(),
      preferredCameraDevice: CameraDevice.rear,
    );
    if (x == null) return null;
    return validate(File(x.path));
  }

  Future<File> validate(File file) async {
    if (!await file.exists()) {
      throw AiException(AppStrings.invalidImage, code: 'missing');
    }

    final name = file.path.toLowerCase();
    final ext = name.contains('.') ? '.${name.split('.').last}' : '';
    if (!_supported.contains(ext)) {
      throw AiException(AppStrings.invalidImage, code: 'format');
    }

    final length = await file.length();
    if (length <= 0) {
      throw AiException(AppStrings.invalidImage, code: 'empty');
    }
    if (length > AppConfig.maxUploadBytes) {
      throw AiException(AppStrings.imageTooLarge, code: 'too_large');
    }

    // Ensure readable
    final raf = await file.open();
    try {
      await raf.read(1);
    } catch (_) {
      throw AiException(AppStrings.invalidImage, code: 'unreadable');
    } finally {
      await raf.close();
    }

    return file;
  }
}
