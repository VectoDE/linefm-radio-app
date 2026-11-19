# R8-Regeln der App (Release: isMinifyEnabled + isShrinkResources).
#
# Flutter und die Plugins bringen eigene Consumer-Regeln mit. Hier steht nur,
# was darueber hinaus gebraucht wird:
# - audio_service: Dienst/Receiver werden ueber das Manifest und vom System
#   (Android Auto, MediaBrowserService) per Name gebunden.
# - flutter_chrome_cast: OPTIONS_PROVIDER_CLASS_NAME im Manifest ist ein
#   String, den das Cast-Framework per Reflexion laedt.
# Ressourcen, die nur per Name geladen werden (Benachrichtigungs-Icon,
# Android-Auto-Senderlogos), schuetzt res/raw/keep.xml.
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.felnanuke.google_cast.** { *; }
-dontwarn com.google.android.play.core.**
