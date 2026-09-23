import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class GoogleAuthStep extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onSkip;

  const GoogleAuthStep({
    super.key,
    required this.onSuccess,
    this.onSkip,
  });

  @override
  State<GoogleAuthStep> createState() => _GoogleAuthStepState();
}

class _GoogleAuthStepState extends State<GoogleAuthStep> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRedirecting = false;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _loadingTimeout;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loadingTimeout?.cancel();
    super.dispose();
  }

  void _checkExistingSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && !_isRedirecting) {
      _isRedirecting = true;
      Future.microtask(() {
        if (mounted) widget.onSuccess();
      });
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (!mounted || _isRedirecting) return;
        final session = data.session;
        if (session != null) {
          _isRedirecting = true;
          _loadingTimeout?.cancel();
          // Небольшая задержка, чтобы токены успели сохраниться
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              try {
                widget.onSuccess();
              } catch (e) {
                debugPrint('GoogleAuthStep onSuccess error: $e');
              }
            }
          });
        }
      },
      onError: (error) {
        debugPrint('GoogleAuthStep auth error: $error');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка авторизации. Попробуйте ещё раз.';
        });
      },
    );
  }

  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 60), () {
      if (!mounted || _isRedirecting) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Время ожидания истекло. Попробуйте ещё раз.';
      });
    });
  }

  void _cancelLoading() {
    _loadingTimeout?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _startLoadingTimeout();

    try {
      // Supabase OAuth — открывает браузер с Google-входом
      // После успешного входа Supabase редиректит обратно в приложение
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://callback',
      );
      // На мобильных устройствах signInWithOAuth не ждёт завершения,
      // так как открывает внешний браузер.
      // _listenToAuthChanges() поймает событие входа.
    } catch (e) {
      debugPrint('GoogleAuthStep Error: $e');
      if (!mounted) return;
      _loadingTimeout?.cancel();
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось войти через Google. '
            'Проверьте настройки Google провайдера в Supabase Dashboard.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _isLoading
                ? _buildLoadingState(tc)
                : _buildGoogleAuthContent(tc),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors tc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        CircularProgressIndicator(color: tc.primary),
        const SizedBox(height: 32),
        Text('Авторизация...',
            style: GoogleFonts.notoSerif(
                fontSize: 20, fontWeight: FontWeight.w900, color: tc.text)),
        const SizedBox(height: 12),
        Text(
          'Откроется окно браузера для входа через Google',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: tc.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 48),
        OutlinedButton(
          onPressed: _cancelLoading,
          style: OutlinedButton.styleFrom(
            foregroundColor: tc.textSecondary,
            side: BorderSide(color: tc.divider),
            minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Отмена'),
        ),
      ],
    );
  }

  Widget _buildGoogleAuthContent(ThemeColors tc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_circle_outlined, size: 80, color: tc.textHint),
        const SizedBox(height: 40),
        Text('Почти готово!',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
                fontSize: 32, fontWeight: FontWeight.w900, color: tc.text)),
        const SizedBox(height: 16),
        Text(
          'Войди через Google, чтобы сохранить свой прогресс',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: tc.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 48),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: _handleSignIn,
          icon: const Icon(Icons.g_mobiledata, size: 26, color: Colors.blue),
          label: const Text('Продолжить с Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tc.card,
            foregroundColor: tc.text,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: tc.divider),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 20),
        if (widget.onSkip != null)
          TextButton(
            onPressed: widget.onSkip,
            child:
                Text('Пропустить', style: TextStyle(color: tc.textHint)),
          ),
      ],
    );
  }
}
