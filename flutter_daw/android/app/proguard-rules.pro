## Flutter / Dart specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.ryanheise.** { *; }

## Keep audio service classes
-keep class androidx.media.** { *; }

## Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
