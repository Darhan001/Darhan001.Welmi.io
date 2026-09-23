import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserDataService _userData = UserDataService();
  final SupabaseService _supabase = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  Gender? _gender;
  DateTime _birthDate = DateTime(1995, 1, 1);

  GoalType? _goal;
  ActivityLevel? _activityLevel;
  double _goalSpeed = 0.5;

  double? _originalWeight;
  XFile? _pickedPhoto;
  bool _photoChanged = false;
  bool _hasChanges = false;

  int get _currentBmr {
    final weight = double.tryParse(_currentWeightCtrl.text) ?? 72;
    final height = double.tryParse(_heightCtrl.text) ?? 175;
    final age = DateTime.now().year - _birthDate.year;
    if (_gender == Gender.male) {
      return (10 * weight + 6.25 * height - 5 * age + 5).round();
    } else if (_gender == Gender.female) {
      return (10 * weight + 6.25 * height - 5 * age - 161).round();
    }
    return 0;
  }

  int get _currentTdee {
    if (_currentBmr == 0) return 0;
    switch (_activityLevel) {
      case ActivityLevel.sedentary: return (_currentBmr * 1.2).round();
      case ActivityLevel.light: return (_currentBmr * 1.375).round();
      case ActivityLevel.moderate: return (_currentBmr * 1.55).round();
      case ActivityLevel.high: return (_currentBmr * 1.725).round();
      case null: return _currentBmr;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await _userData.loadAll();

    final profile = _userData.profile;

    _nameCtrl.text = profile?.displayName ?? AuthService().displayName ?? '';
    _heightCtrl.text = (profile?.heightCm ?? 175).toStringAsFixed(0);
    _currentWeightCtrl.text = (profile?.currentWeightKg ?? 72).toStringAsFixed(1);
    _targetWeightCtrl.text = (profile?.targetWeightKg ?? 70).toStringAsFixed(1);

    _originalWeight = double.tryParse(_currentWeightCtrl.text);
    _gender = profile?.gender;
    _birthDate = profile?.birthDate ?? DateTime(1995, 1, 1);
    _goal = profile?.goal;
    _activityLevel = profile?.activityLevel;
    _goalSpeed = profile?.goalSpeedKgPerWeek ?? 0.5;

    if (mounted) setState(() => _isLoading = false);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A8C5C),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final tc = ThemeColors.of(context);
    final source = await showModalBottomSheet<ImageSource>(
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
          children: [             Text(AppLocalizations.of(context)!.changePhoto,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: tc.text)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSourceOption(
                    tc,
                    Icons.photo_library_outlined,                     AppLocalizations.of(context)!.gallery,
                    ImageSource.gallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoSourceOption(
                    tc,
                    Icons.camera_alt_outlined,                     AppLocalizations.of(context)!.camera,
                    ImageSource.camera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final photo = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null) return;

    setState(() {
      _pickedPhoto = photo;
      _photoChanged = true;
      _hasChanges = true;
    });
  }

  Widget _buildPhotoSourceOption(
      ThemeColors tc, IconData icon, String label, ImageSource source) {
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
            Icon(icon, size: 28, color: const Color(0xFF4A8C5C)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: tc.text)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final auth = AuthService();
    final existing = _userData.profile;
    final userId = auth.userId ?? existing?.id;
    if (userId == null || userId.isEmpty) {
      showWelmiSnackbar(context, '❌ Не удалось определить пользователя',
          icon: Icons.error_outline);
      return;
    }

    final profile = UserProfile(
      id: userId,
      displayName:
          _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : existing?.displayName,
      email: existing?.email ?? auth.email,
      photoUrl: existing?.photoUrl ?? auth.photoUrl,
      heightCm: double.tryParse(_heightCtrl.text) ?? existing?.heightCm ?? 175,
      currentWeightKg:
          double.tryParse(_currentWeightCtrl.text) ?? existing?.currentWeightKg ?? 72,
      targetWeightKg:
          double.tryParse(_targetWeightCtrl.text) ?? existing?.targetWeightKg ?? 70,
      gender: _gender,
      goal: _goal,
      activityLevel: _activityLevel,
      goalSpeedKgPerWeek: _goalSpeed,
      birthDate: _birthDate,
      subscriptionTier: existing?.subscriptionTier,
      subscriptionExpiresAt: existing?.subscriptionExpiresAt,
      unitsSystem: existing?.unitsSystem,
      notificationPrefs: existing?.notificationPrefs,
    );

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    String? photoWarning;
    try {
      if (_photoChanged && _pickedPhoto != null) {
        try {
          final photoUrl =
              await _supabase.uploadProfilePhoto(userId, _pickedPhoto!);
          profile.photoUrl = photoUrl;
        } catch (e) {
          debugPrint('❌ Photo upload error: $e');
          photoWarning = 'Фото не загрузилось';
        }
      }

      await _userData.saveProfile(profile);
      final newWeight = double.tryParse(_currentWeightCtrl.text);
      final weightChanged = newWeight != null &&
          (_originalWeight == null ||
              (newWeight - _originalWeight!).abs() > 0.01);
      if (weightChanged) {
        try {
          await _userData.saveWeight(newWeight);
        } catch (w) {
          debugPrint('❌ EditProfile weight save error: $w');
        }
      }

      auth.updateProfileInfo(
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
      );

      await _userData.loadAll();

      if (mounted) {
        setState(() => _hasChanges = false);
        showWelmiSnackbar(
          context,
          photoWarning != null
              ? '✅ Профиль сохранён. ⚠️ $photoWarning'
              : '✅ Профиль обновлён!',
          icon: photoWarning != null
              ? Icons.warning_amber_rounded
              : Icons.check_circle,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ EditProfile save error: $e');
      if (mounted) {
        showWelmiSnackbar(context, '❌ Ошибка сохранения', icon: Icons.error_outline);
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: tc.primary),
                const SizedBox(height: 16),
                Text('Загружаем профиль...',
                    style: GoogleFonts.inter(
                        color: tc.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasChanges) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_hasChanges) {
                              _showDiscardDialog();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tc.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.arrow_back, size: 22, color: tc.text),
                          ),
                        ),                         Text(AppLocalizations.of(context)!.editProfileTitle,
                            style: GoogleFonts.notoSerif(
                                fontWeight: FontWeight.w900, fontSize: 18, color: tc.text)),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAvatarSection(tc),
                    const SizedBox(height: 32),
                    _buildSectionTitle(AppLocalizations.of(context)!.personalInfo, tc),
                    const SizedBox(height: 12),
                    _buildGlassCard(tc, children: [
                      _buildTextField(
                        tc: tc,
                        icon: Icons.person_outline,
                        label: AppLocalizations.of(context)!.nameLabel,
                        controller: _nameCtrl,
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      _buildGenderSelector(tc),
                      const SizedBox(height: 16),
                      _buildDatePicker(tc),
                    ]),
                    const SizedBox(height: 28),
                    _buildSectionTitle(AppLocalizations.of(context)!.bodyType, tc),
                    const SizedBox(height: 12),
                    _buildGlassCard(tc, children: [
                      _buildTextField(
                        tc: tc,
                        icon: Icons.height,
                        label: AppLocalizations.of(context)!.heightCm,
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        suffix: 'см',
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        tc: tc,
                        icon: Icons.monitor_weight_outlined,                         label: AppLocalizations.of(context)!.currentWeightLabel,
                        controller: _currentWeightCtrl,
                        keyboardType: TextInputType.number,
                        suffix: 'кг',
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        tc: tc,
                        icon: Icons.flag_outlined,                         label: AppLocalizations.of(context)!.targetWeight,
                        controller: _targetWeightCtrl,
                        keyboardType: TextInputType.number,
                        suffix: 'кг',
                        onChanged: (_) => _markChanged(),
                      ),
                    ]),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              if (_hasChanges)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: _buildSaveButton(tc),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ThemeColors tc) {
    final auth = AuthService();
    final photoUrl = _userData.profile?.photoUrl ?? auth.photoUrl;
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : auth.displayName ?? 'Пользователь';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bmr = _currentBmr;
    final tdee = _currentTdee;

    return Column(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _pickPhoto,
          child: Stack(
            children: [
              _pickedPhoto != null
                  ? ClipOval(
                      child: kIsWeb 
                        ? Image.network(
                            _pickedPhoto!.path,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_pickedPhoto!.path),
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                    )
                  : CircleAvatar(
                      radius: 52,
                      backgroundColor: tc.card,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(initial,
                              style: GoogleFonts.inter(
                                  color: tc.text,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A8C5C),
                    shape: BoxShape.circle,
                    border: Border.all(color: tc.background, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.tapPhotoToChange,
            style: TextStyle(fontSize: 11, color: tc.textHint)),
        const SizedBox(height: 6),
        if (bmr > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'BMR $bmr ккал · TDEE $tdee ккал',
              style: GoogleFonts.inter(
                  color: const Color(0xFF4A8C5C),
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderSelector(ThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wc, size: 18, color: tc.textHint),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.genderLabel,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: tc.textHint)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGenderChip(                 tc, Gender.male, AppLocalizations.of(context)!.male, Icons.male, _gender == Gender.male),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderChip(                 tc, Gender.female, AppLocalizations.of(context)!.female, Icons.female, _gender == Gender.female),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip(ThemeColors tc, Gender gender, String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = gender;
          _hasChanges = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F3E5)
              : tc.text.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A8C5C)
                : tc.text.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? const Color(0xFF4A8C5C) : tc.textHint),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF4A8C5C) : tc.text,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeColors tc) {
    final df = DateFormat('d MMMM yyyy', 'ru');
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.text.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.text.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: tc.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.birthDate,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: tc.textHint)),
                  const SizedBox(height: 4),
                  Text(df.format(_birthDate),
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: tc.text)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month,
                  size: 18, color: Color(0xFF4A8C5C)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeColors tc,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tc.text.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.text.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tc.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: tc.text),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: tc.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffix != null)
            Text(suffix,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: tc.textHint)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeColors tc) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4A8C5C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w900, fontSize: 18, color: tc.text)),
      ],
    );
  }

  Widget _buildGlassCard(ThemeColors tc, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSaveButton(ThemeColors tc) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A8C5C), Color(0xFF75A47F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A8C5C).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.saveChanges,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    final tc = ThemeColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Expanded(               child: Text(AppLocalizations.of(context)!.discardChanges,
                  style: TextStyle(fontWeight: FontWeight.w900, color: tc.text)),
            ),
          ],
        ),
        content: Text('У вас есть несохранённые изменения. Они будут потеряны.',
            style: TextStyle(color: tc.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Остаться',
                style: TextStyle(fontWeight: FontWeight.w700, color: tc.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Выйти',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
