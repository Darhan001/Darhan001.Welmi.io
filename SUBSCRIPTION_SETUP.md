# Welmi Premium — настройка подписок

## Что уже подготовлено в приложении

- Экран Welmi Premium запрашивает предложения у App Store / Google Play и показывает форматированную цену, полученную от магазина. В исходниках нет цен.
- Покупка запускается через официальный Flutter `in_app_purchase` API; обновления `purchased`, `restored`, `canceled`, `pending` и `error` обрабатываются через `purchaseStream`.
- Восстановление покупок вызывает системный магазин. Для покупки и восстановления сервер повторно проверяет entitlement.
- Источником доступа служит `subscription_entitlements` в Supabase. Клиент не записывает подписку сам; доступ закрыт, пока сервер не подтвердил entitlement.
- Сканер еды закрыт компонентом `PremiumAccessGate` для пользователей без действующего серверного entitlement.
- Edge Functions подготовлены в `supabase/functions/verify-subscription/`, `supabase/functions/store-notifications/` и `supabase/functions/_shared/subscription_verification.ts`. Google Play проверяется через Android Publisher API v2; Apple — через App Store Server API и Apple signed transaction verifier.
- SQL-миграция находится в `supabase/migrations/202609300001_subscription_entitlements.sql`. Она не применялась к Supabase.

Покупка не активирует Premium на одном факте ответа магазина: Edge Function сверяет транзакцию с платформой, привязывает её к текущему Supabase user и только затем записывает entitlement. Приватные purchase tokens доступны только серверному service role. Apple требует App Store Server API credentials и Apple Root Certificates; Google — сервисный аккаунт с доступом к Android Publisher API. Секреты нужны только Edge Functions.

## Product ID, заданные в коде

Создайте одинаковые идентификаторы в обоих магазинах:

| Период | Product ID |
| --- | --- |
| Месяц | `welmi_premium_monthly` |
| Год | `welmi_premium_yearly` |

Идентификаторы объявлены в `lib/features/profile/data/subscription_repository.dart` и должны совпадать с App Store Connect и Play Console. Цена, валюта и локализованная строка берутся только из `ProductDetails.price` магазина. У приложения сейчас Android package `com.example.lumina`; iOS bundle ID нужно сверить в Xcode перед созданием продуктов и указать тот же ID в серверных secrets.

## Google Play Console — вручную

1. Создайте приложение в Play Console и загрузите хотя бы внутренний тестовый Android App Bundle, подписанный тем же application ID, что и релиз. Покупки тестируйте через Google Play, не sideload APK.
2. Откройте **Monetize with Play → Products → Subscriptions** и создайте `welmi_premium_monthly` и `welmi_premium_yearly`.
3. Для месячного продукта создайте активный monthly base plan; для годового — активный yearly base plan. Установите доступность стран, цену и налоги в Play Console. Если добавляете offers, настройте eligibility; приложение передаёт offer token, возвращённый магазином.
4. Активируйте подписки и base plans. Опубликованный продукт может оставаться недоступным до публикации приложения/трекового релиза и прохождения обработки магазина.
5. В **Setup → License testing** добавьте Google-аккаунты тестировщиков. Они должны принять приглашение и установить приложение из Play internal testing.
6. В Google Cloud свяжите проект с Play Console, включите **Google Play Android Developer API**, создайте отдельный service account и предоставьте ему минимально необходимые права просмотра подписок в Play Console (**Users and permissions**). Не помещайте JSON-ключ в Flutter, Git или этот документ.
7. Настройте Real-time developer notifications: создайте Pub/Sub topic, укажите его в Play Console, создайте push subscription на URL `https://<project-ref>.supabase.co/functions/v1/store-notifications` и включите OIDC token с отдельным service account. Audience должен совпасть со значением `PUBSUB_OIDC_AUDIENCE`; email — с `PUBSUB_SERVICE_ACCOUNT_EMAIL`.
8. Проверьте покупку, отмену, истечение, grace period, возврат и восстановление на внутренних тестовых аккаунтах.

## App Store Connect — вручную

1. В Xcode установите реальный unique Bundle Identifier для target Runner; он должен совпасть с Bundle ID приложения в App Store Connect. Не выпускайте приложение с `com.example.lumina`.
2. В App Store Connect создайте **Subscription Group** (например, `Welmi Premium`) и добавьте в неё auto-renewable subscription `welmi_premium_monthly` с длительностью 1 месяц и `welmi_premium_yearly` с длительностью 1 год.
3. Заполните локализованные названия, описания, review information и установите цены/территории в App Store Connect. Не добавляйте цену в Flutter.
4. Проверьте уровни подписок/переходов внутри группы, локализации и статус продуктов. Для первого IAP обычно отправьте продукты на ревью вместе с новой версией приложения.
5. Создайте Sandbox Apple Account в App Store Connect → Users and Access → Sandbox Testers. На iOS устройстве выйдите из Media & Purchases, войдите тестовым Sandbox аккаунтом в системном диалоге и установите тестовую сборку через TestFlight либо подходящую StoreKit sandbox-сборку.
6. В App Store Connect → Users and Access → Integrations → In-App Purchase создайте API key. Сохраните `Issuer ID`, `Key ID` и `.p8` private key в защищённое хранилище; ключ скачивается Apple один раз.
7. Скачайте официальные Apple Root Certificates (как минимум актуальную цепочку Apple Root CA G3) с Apple PKI, кодируйте DER-файлы в base64 и передайте серверу в `APPLE_ROOT_CERTIFICATES_BASE64` как список base64 значений через запятую.
8. В App Store Connect задайте App Store Server Notifications V2 URL `https://<project-ref>.supabase.co/functions/v1/store-notifications` для Production и Sandbox. Уведомления подписаны Apple и проверяются функцией.

## Supabase: схема, секреты и Edge Functions

Сначала проверьте проект/окружение Supabase и сделайте обычный резервный план. Затем вручную примените миграцию `supabase/migrations/202609300001_subscription_entitlements.sql` в SQL Editor или через утверждённый процесс миграций. Этот SQL создаёт:

- `subscription_entitlements`: одна текущая запись на пользователя; authenticated user может только читать собственную строку;
- `subscription_store_transactions`: серверная связь транзакций и purchase tokens с пользователем; клиентских RLS policies нет.

Не запускайте SQL из этого репозитория вслепую на production: сначала сверьте схему и политику миграций. Затем задайте Edge Function secrets через Supabase CLI/секретное хранилище. Например, значения подставляются локально, не публикуются и не кладутся в Flutter:

```text
ANDROID_PACKAGE_NAME=com.example.lumina
GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64=<base64 JSON service account>
APPLE_BUNDLE_ID=<real iOS Bundle ID>
APPLE_APP_ID=<numeric App Store app ID>
APPLE_IAP_ISSUER_ID=<Issuer ID>
APPLE_IAP_KEY_ID=<Key ID>
APPLE_IAP_PRIVATE_KEY=<contents of the .p8 file>
APPLE_ROOT_CERTIFICATES_BASE64=<comma-separated base64 Apple root certificates>
PUBSUB_OIDC_AUDIENCE=<exact audience configured on the Pub/Sub push subscription>
PUBSUB_SERVICE_ACCOUNT_EMAIL=<email of the Pub/Sub OIDC service account>
```

Supabase Edge runtime already supplies `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY`; не копируйте service role key в приложение. Разверните `verify-subscription` с обычной проверкой Supabase JWT. Для `store-notifications` отключите только встроенную проверку Supabase JWT при deploy (Apple/Google не посылают пользовательский Supabase JWT); функцию защищают проверка подписи Apple Server Notifications V2 и проверка OIDC JWT Pub/Sub.

После настройки выполните ручные deploy функций по принятому процессу проекта и проверьте логи. Доступ должен оставаться закрытым, пока products не созданы, Edge Function не настроена, а Store API не подтвердил транзакцию.

## Проверка перед релизом

- Установите релизный Android application ID и iOS Bundle ID, затем обновите соответствующие secrets.
- Убедитесь, что оба Product ID active и цены назначены в доступных регионах.
- Проверьте, что SQL применён, RLS включён, authenticated-пользователь не может писать таблицы, service role может обновлять их.
- Проверьте новый и существующий аккаунт, месячную/годовую оплату, отмену платёжного окна, pending, отказ магазина, восстановление на переустановке, смену Welmi-аккаунта, продление, grace period, отмену автопродления, refund/revoke и истечение.
- В клиенте нет offline/local premium override; при недоступности Supabase entitlement доступ не расширяется локальным флагом.
