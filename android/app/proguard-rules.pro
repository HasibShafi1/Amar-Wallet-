# Keep the speech recognition services and intents
-keep class android.speech.** { *; }
-keep interface android.speech.** { *; }

# Keep the Speech To Text plugin classes
-keep class com.dexteriv.speech_to_text.** { *; }

# Keep common Google and Audio dependencies that handle speech
-keep class com.google.android.gms.common.api.GoogleApiClient { *; }
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable { *; }
-keep class com.deezer.sdk.** { *; }
-keep interface com.deezer.sdk.** { *; }
