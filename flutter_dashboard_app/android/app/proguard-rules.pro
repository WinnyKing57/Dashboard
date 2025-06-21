# Flutter framework basic rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.facade.**  { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class androidx.lifecycle.** { *; }

# --- IMPORTANT ---
# The rules above are a basic set for Flutter.
# You MUST add rules for an
# y native code specific to your app, and for each plugin you use.
# Failure to do so will likely result in crashes or unexpected behavior
# when `isMinifyEnabled = true` (R8/ProGuard minification).
#
# Consult the documentation for each plugin for its specific ProGuard rules.
# For example, if you use a plugin like `some_plugin` that has native Android code,
# you might need to add something like:
# -keep class com.example.some_plugin.** { *; }
#
# Add plugin-specific rules below this line:
# Example:
#
# Rules for `just_audio` / `audio_service` (check their documentation for the most up-to-date rules)
# -keep class com.ryanheise.just_audio.** { *; }
# -keep class com.ryanheise.audioservice.** { *; }
#
# Rules for `workmanager` (check its documentation)
# -keep public class * extends androidx.work.ListenableWorker {
#    public <init>(android.content.Context,androidx.work.WorkerParameters);
# }
#
# Rules for `flutter_local_notifications` (check its documentation)
# -keep class com.dexterous.flutterlocalnotifications.** { *; }

# Add your custom rules here, if any.

# Rules for audio_service (used by just_audio_background and just_audio)
# These ensure that the components declared in AndroidManifest.xml are not removed or renamed.
-keep class com.ryanheise.audioservice.AudioServiceActivity { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }

# Rules for workmanager
# Keeps the ListenableWorker implementations and the plugin classes.
-keep public class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class dev.fluttercommunity.workmanager.** { *; }
# Ensure the callback dispatcher is not removed if specified in Dart code with @pragma('vm:entry-point')
# This is generally handled by Flutter's own Proguard rules, but doesn't hurt to be aware.
