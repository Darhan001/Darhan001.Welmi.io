# Flutter 3D Controller & WebView protection
-keepattributes Signature,Exceptions,Annotation

# flutter_local_notifications хранит запланированные уведомления в JSON
# через Gson (в т.ч. в фоновом ScheduledNotificationReceiver). Без этих
# правил R8 вырезает generic-сигнатуры TypeToken, Gson падает с
# «Missing type parameter», и ЗАПЛАНИРОВАННЫЕ уведомления молча не
# показываются (при этом мгновенный show() продолжает работать).
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.JsonDeserializer
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
