# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class hive.** { *; }
-keepclassmembers class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite {
    <fields>;
}

# Keep model classes for Hive (adjust package name if needed)
-keep class com.ktso7.ledgerify.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Timezone
-keep class org.threeten.** { *; }

# General Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Play Core (for deferred components - ignore missing classes)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
