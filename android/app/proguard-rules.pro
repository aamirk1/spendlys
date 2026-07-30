# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.internal.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Generated Plugin Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve attributes for reflections, serializations, annotations
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Suppress warnings for optional Play Core and Flutter deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson
-keep class com.google.gson.** { *; }

# Hive
-keep class dev.hive.** { *; }
