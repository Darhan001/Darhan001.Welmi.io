import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/profile/domain/profile_metrics.dart';
import 'package:lumina/features/profile/presentation/widgets/edit_profile_discard_dialog.dart';
import 'package:lumina/features/profile/presentation/widgets/edit_profile_form_parts.dart';
import 'package:lumina/features/profile/presentation/widgets/edit_profile_photo.dart';
import 'package:lumina/features/profile/presentation/widgets/edit_profile_selectors.dart';
import 'package:lumina/l10n/app_localizations.dart';

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

  /// Вес из поля в килограммах (поле показывает выбранные единицы).
  double? _weightKgFrom(TextEditingController ctrl) {
    final value = parseDecimalInput(ctrl.text);
    return value == null
        ? null
        : UnitsService.instance.weightFromDisplay(value);
  }

  /// BMR 0 — если данных недостаточно: без введённых значений не считаем
  /// по выдуманным 72 кг и 175 см.
  int get _currentBmr => calculateBmr(
    weightKg: _weightKgFrom(_currentWeightCtrl),
    heightCm: parseDecimalInput(_heightCtrl.text),
    birthDate: _birthDate,
    gender: _gender,
  );

  int get _currentTdee => calculateTdee(_currentBmr, _activityLevel);

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
    // Без профиля поля пустые: выдуманные значения попали бы в БД при сохранении.
    final units = UnitsService.instance;
    _heightCtrl.text = profile == null
        ? ''
        : profile.heightCm.toStringAsFixed(0);
    _currentWeightCtrl.text = profile == null
        ? ''
        : units.weightToDisplay(profile.currentWeightKg).toStringAsFixed(1);
    _targetWeightCtrl.text = profile == null
        ? ''
        : units.weightToDisplay(profile.targetWeightKg).toStringAsFixed(1);

    _originalWeight = _weightKgFrom(_currentWeightCtrl);
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
    final source = await showPhotoSourceSheet(context);
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

  Future<void> _saveProfile() async {
    final auth = AuthService();
    final existing = _userData.profile;
    final userId = auth.userId ?? existing?.id;
    if (userId == null || userId.isEmpty) {
      showWelmiSnackbar(
        context,
        '❌ Не удалось определить пользователя',
        icon: Icons.error_outline,
      );
      return;
    }

    // Проверяем ввод до сохранения: раньше опечатка «1750» или пустое поле
    // без профиля записывали в БД нереальный рост или выдуманные 175/72/70.
    final loc = AppLocalizations.of(context)!;
    final heightCm = parseDecimalInput(_heightCtrl.text) ?? existing?.heightCm;
    final currentKg =
        _weightKgFrom(_currentWeightCtrl) ?? existing?.currentWeightKg;
    final targetKg =
        _weightKgFrom(_targetWeightCtrl) ?? existing?.targetWeightKg;
    if (heightCm == null || !isPlausibleHeightCm(heightCm)) {
      showWelmiSnackbar(context, loc.heightInvalid, icon: Icons.error_outline);
      return;
    }
    if (currentKg == null ||
        targetKg == null ||
        !isPlausibleWeightKg(currentKg) ||
        !isPlausibleWeightKg(targetKg)) {
      showWelmiSnackbar(context, loc.weightInvalid, icon: Icons.error_outline);
      return;
    }

    final profile = UserProfile(
      id: userId,
      displayName: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : existing?.displayName,
      email: existing?.email ?? auth.email,
      photoUrl: existing?.photoUrl ?? auth.photoUrl,
      heightCm: heightCm,
      currentWeightKg: currentKg,
      targetWeightKg: targetKg,
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
          final photoUrl = await _supabase.uploadProfilePhoto(
            userId,
            _pickedPhoto!,
          );
          profile.photoUrl = photoUrl;
        } catch (e) {
          debugPrint('❌ Photo upload error: $e');
          photoWarning = 'Фото не загрузилось';
        }
      }

      await _userData.saveProfile(profile);
      final newWeight = currentKg;
      final weightChanged =
          _originalWeight == null ||
          (newWeight - _originalWeight!).abs() > 0.01;
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
        showWelmiSnackbar(
          context,
          '❌ Ошибка сохранения',
          icon: Icons.error_outline,
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  /// Выход из формы: при несохранённых изменениях сначала спрашиваем.
  Future<void> _leave() async {
    if (_hasChanges && !await confirmDiscardProfileChanges(context)) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;

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
                Text(
                  'Загружаем профиль...',
                  style: GoogleFonts.inter(
                    color: tc.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auth = AuthService();
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : auth.displayName ?? 'Пользователь';

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasChanges) _leave();
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
                          onTap: _leave,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tc.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: tc.text,
                            ),
                          ),
                        ),
                        Text(
                          loc.editProfileTitle,
                          style: GoogleFonts.notoSerif(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: tc.text,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProfileAvatarPicker(
                      name: name,
                      photoUrl: _userData.profile?.photoUrl ?? auth.photoUrl,
                      pickedPhoto: _pickedPhoto,
                      bmr: _currentBmr,
                      tdee: _currentTdee,
                      isSaving: _isSaving,
                      onTap: _pickPhoto,
                    ),
                    const SizedBox(height: 32),
                    ProfileSectionTitle(loc.personalInfo),
                    const SizedBox(height: 12),
                    ProfileFormCard(
                      children: [
                        ProfileTextField(
                          icon: Icons.person_outline,
                          label: loc.nameLabel,
                          controller: _nameCtrl,
                          onChanged: (_) => _markChanged(),
                        ),
                        const SizedBox(height: 16),
                        GenderSelector(
                          value: _gender,
                          onChanged: (gender) => setState(() {
                            _gender = gender;
                            _hasChanges = true;
                          }),
                        ),
                        const SizedBox(height: 16),
                        BirthDateField(value: _birthDate, onTap: _pickDate),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ProfileSectionTitle(loc.bodyType),
                    const SizedBox(height: 12),
                    ProfileFormCard(
                      children: [
                        ProfileTextField(
                          icon: Icons.height,
                          label: loc.heightCm,
                          controller: _heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffix: loc.unitCm,
                          onChanged: (_) => _markChanged(),
                        ),
                        const SizedBox(height: 16),
                        ProfileTextField(
                          icon: Icons.monitor_weight_outlined,
                          label: loc.currentWeightLabel,
                          controller: _currentWeightCtrl,
                          // На iOS TextInputType.number не даёт ввести дробную часть.
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffix: loc.weightUnitLabel,
                          onChanged: (_) => _markChanged(),
                        ),
                        const SizedBox(height: 16),
                        ProfileTextField(
                          icon: Icons.flag_outlined,
                          label: loc.targetWeight,
                          controller: _targetWeightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffix: loc.weightUnitLabel,
                          onChanged: (_) => _markChanged(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              if (_hasChanges)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: ProfileSaveButton(
                    label: loc.saveChanges,
                    saving: _isSaving,
                    onPressed: _saveProfile,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
