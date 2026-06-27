# Rihla release ProGuard/R8 keep rules.

# Flutter engine + embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# MapLibre GL native
-keep class org.maplibre.** { *; }
-keep class com.mapbox.** { *; }
-dontwarn org.maplibre.**
-dontwarn com.mapbox.**

# Geolocator / permission_handler
-keep class com.baseflow.** { *; }

# Supabase / OkHttp / Kotlin metadata (reflection-based serialization)
-keep class io.github.jan.supabase.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep class kotlin.Metadata { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep model classes that rely on reflective JSON (defensive)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Suppress common shrinker warnings for optional deps
-dontwarn javax.annotation.**
