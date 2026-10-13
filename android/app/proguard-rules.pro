# Release builds are shrunk by R8. These keep rules stop it from removing
# classes that are only created by reflection, which crashes the app at
# launch ("Failed to create an instance of androidx.work.impl.WorkDatabase").

# WorkManager (used by the Google Mobile Ads SDK) builds its Room database
# by reflection.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Google Play Billing (in-app purchases).
-keep class com.android.vending.billing.** { *; }
