# Flutter 3D Controller & WebView protection
-keepattributes Signature,Exceptions,Annotation
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
