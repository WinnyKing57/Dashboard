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

# --- Règles spécifiques aux PLUGINS à ajouter CI-DESSOUS ---
# Remplacez ou complétez ces exemples avec les recommandations officielles de chaque plugin.

# Pour just_audio, just_audio_background, et audio_service:
# Ces trois plugins sont souvent utilisés ensemble et leurs règles peuvent interagir.
# Il est crucial de consulter la documentation de Ryan Heise (le développeur)
# ou les issues GitHub pour les configurations ProGuard recommandées.
# Exemple général (VÉRIFIEZ LA DOCUMENTATION !) :
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio_background.** { *; } # Si ce package existe séparément
-keep class com.ryanheise.audioservice.** { *; }
-keepnames class com.ryanheise.audioservice.AudioServiceActivity # Si vous l'utilisez comme activité principale
-keep public class * extends androidx.media.MediaBrowserServiceCompat { # Pour audio_service
    public <init>();
    public void Landroid.os.IBinder; onBind(android.content.Intent);
}
-keep public class * extends android.support.v4.media.session.MediaSessionCompat.Callback { # Pour audio_service
    public <init>();
}

# Pour workmanager:
# (Consultez la documentation de flutter_workmanager)
# Souvent, il faut préserver les Workers.
-keep public class * extends androidx.work.ListenableWorker {
   public <init>(android.content.Context,androidx.work.WorkerParameters);
}
# Si vous utilisez des noms de classe spécifiques pour vos workers dans votre code Dart :
# -keepnames class com.votredomaine.votreapp.YourWorkerClassName

# Pour flutter_local_notifications:
# (Consultez la documentation de flutter_local_notifications)
# Exemple général :
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }


# Pour hive / hive_flutter:
# Hive génère des TypeAdapters. Si vous n'utilisez pas `registerAdapter` avec des instances
# mais avec des chaînes de caractères (moins courant), vous pourriez avoir besoin de règles.
# Mais généralement, si vous suivez les pratiques standard, ce n'est pas nécessaire.
# Si vous rencontrez des problèmes avec Hive après minification :
# -keep class * implements com.hive.TypeAdapter { *; }
# -keep class votre_package.nom_de_vos_classes_hive.** { *; }


# Pour file_picker:
# (Consultez la documentation de file_picker)
# Souvent, les problèmes sont liés aux `ContentProvider` ou aux activités qu'il lance.
# Exemple général :
-keep class com.mr.flutter.plugin.filepicker.** { *; }
# Peut nécessiter des règles pour les activités Android qu'il utilise si elles sont obfusquées.

# Pour url_launcher:
# Généralement, pas besoin de règles spécifiques car il utilise des intents Android standards.
# Si problèmes :
# -keep class io.flutter.plugins.urllauncher.** { *; }

# Pour share_plus:
# Similaire à url_launcher, utilise des intents standards.
# Si problèmes :
# -keep class io.flutter.plugins.shareplus.** { *; }

# --- FIN des règles spécifiques aux plugins ---

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
