import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _userId;
  String? _displayName;
  String? _email;
  String? _photoUrl;
  bool _isSignedIn = false;

  String? get userId => _userId;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get photoUrl => _photoUrl;
  bool get isSignedIn => _isSignedIn;

  /// Синхронизация с Supabase сессией
  void syncFromSession(User user) {
    _userId = user.id;
    _displayName = user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email?.split('@').first ??
        'Пользователь';
    _email = user.email;
    _photoUrl = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;
    _isSignedIn = user.id.isNotEmpty;
  }

  /// Обновить кешированные данные профиля после редактирования
  void updateProfileInfo({String? displayName, String? email, String? photoUrl}) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    if (email != null) _email = email;
    if (photoUrl != null) _photoUrl = photoUrl;
  }

  /// Сброс при выходе
  void reset() {
    _userId = null;
    _displayName = null;
    _email = null;
    _photoUrl = null;
    _isSignedIn = false;
  }

  /// Проверка, завершён ли онбординг
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Пометка что онбординг завершён
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  /// Выход из Supabase
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
  }
}
