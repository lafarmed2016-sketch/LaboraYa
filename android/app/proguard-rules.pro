# Flutter Proguard & R8 Rules

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services & Play Core
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**

# Image Cropper (uCrop)
-dontwarn com.yalantis.ucrop.**

# General rule to prevent R8 build failures for unused/optional plugin dependencies
-dontwarn **
