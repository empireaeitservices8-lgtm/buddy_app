# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Deferred components / SplitCompat)
-dontwarn com.google.android.play.core.**

# Agora RTC Engine Proguard Rules
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Firebase Proguard Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Dio / OkHttp Proguard Rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
