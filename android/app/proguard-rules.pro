# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase SDKs
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep models with Gson (Firestore)
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }

# Flutter plugins (camera, image picker, etc.)
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.camera.** { *; }

# Multidex support
-keep class androidx.multidex.** { *; }

# Keep MainActivity
-keep class com.example.opay.MainActivity { *; }

# Method channels
-keep class io.flutter.plugin.common.MethodChannel { *; }

# Keep annotations
-keepattributes *Annotation*
