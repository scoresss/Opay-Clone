# Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firestore models
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Your package
-keep class com.example.opay.** { *; }
-dontwarn com.example.opay.**

# Messaging
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }

# AndroidX
-dontwarn androidx.**
-keep class androidx.** { *; }

# JSON models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
