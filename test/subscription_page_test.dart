import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/profile/presentation/pages/subscription_page.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экран Premium раньше мог вечно показывать индикатор загрузки: состояние по
/// умолчанию было `loading`, а инициализация магазина покупок могла упасть без
/// перехода в другое состояние.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('экран Premium не зависает на загрузке без магазина',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SubscriptionPage(),
      ),
    );
    // Даём сработать таймаутам загрузки товаров и проверки подписки.
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 15));

    expect(find.byType(SubscriptionPage), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Welmi Premium'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
