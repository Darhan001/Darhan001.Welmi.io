import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Аватар в форме профиля: выбранное фото, текущее фото или первая буква,
/// значок камеры и (если данных хватает) рассчитанные BMR и TDEE.
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.name,
    required this.bmr,
    required this.tdee,
    required this.isSaving,
    required this.onTap,
    this.pickedPhoto,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final XFile? pickedPhoto;
  final int bmr;
  final int tdee;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
      children: [
        GestureDetector(
          onTap: isSaving ? null : onTap,
          child: Stack(
            children: [
              _avatar(context, tc, initial),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tc.greenDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: tc.background, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.tapPhotoToChange,
          style: TextStyle(fontSize: 11, color: tc.textHint),
        ),
        const SizedBox(height: 6),
        if (bmr > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tc.successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'BMR $bmr ккал · TDEE $tdee ккал',
              style: GoogleFonts.inter(
                color: tc.greenDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatar(BuildContext context, ThemeColors tc, String initial) {
    final picked = pickedPhoto;
    if (picked != null) {
      return ClipOval(
        child: kIsWeb
            ? Image.network(
                picked.path,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(picked.path),
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              ),
      );
    }

    final url = photoUrl;
    return CircleAvatar(
      radius: 52,
      backgroundColor: tc.card,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url != null
          ? null
          : Text(
              initial,
              style: GoogleFonts.inter(
                color: tc.text,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

/// Спрашивает источник фото: галерея или камера.
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  final tc = ThemeColors.of(context);
  final loc = AppLocalizations.of(context)!;

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.changePhoto,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_outlined,
                  label: loc.gallery,
                  source: ImageSource.gallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: loc.camera,
                  source: ImageSource.camera,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final ImageSource source;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: tc.text.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.text.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: tc.greenDark),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: tc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
