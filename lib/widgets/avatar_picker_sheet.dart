import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

enum AvatarPickerAction {
  camera,
  gallery,
  delete,
}

class AvatarPickerResult {
  final AvatarPickerAction action;
  final String? filePath;

  const AvatarPickerResult._({required this.action, this.filePath});

  factory AvatarPickerResult.image(String filePath, {bool fromCamera = false}) =>
      AvatarPickerResult._(
        action: fromCamera ? AvatarPickerAction.camera : AvatarPickerAction.gallery,
        filePath: filePath,
      );

  factory AvatarPickerResult.deleted() =>
      const AvatarPickerResult._(action: AvatarPickerAction.delete);
}

class AvatarPickerSheet extends StatelessWidget {
  final bool hasExistingImage;

  const AvatarPickerSheet({
    super.key,
    this.hasExistingImage = false,
  });

  static Future<AvatarPickerResult?> show(
    BuildContext context, {
    bool hasExistingImage = false,
    ImagePicker? imagePicker,
  }) async {
    return showModalBottomSheet<AvatarPickerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AvatarPickerSheet(hasExistingImage: hasExistingImage),
    );
  }

  Future<void> _handlePick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!context.mounted) return;
      if (file != null) {
        Navigator.pop(
          context,
          AvatarPickerResult.image(
            file.path,
            fromCamera: source == ImageSource.camera,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E232B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Profil Fotoğrafı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF0A49A6)).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF0A49A6),
                  size: 22,
                ),
              ),
              title: Text(
                'Fotoğraf Çek',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              subtitle: Text(
                'Kamera ile anlık yeni bir fotoğraf çekin',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              onTap: () => _handlePick(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              title: Text(
                'Galeriden Seç',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              subtitle: Text(
                'Cihazınızdaki fotoğraflardan birini seçin',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              onTap: () => _handlePick(context, ImageSource.gallery),
            ),
            if (hasExistingImage) ...[
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Fotoğrafı Kaldır',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  'Mevcut profil görselini kaldırıp varsayılana dönün',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(context, AvatarPickerResult.deleted());
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
}
