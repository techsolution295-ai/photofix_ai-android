# AdMob / UMP / Play Billing
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.ump.**
-dontwarn com.android.billingclient.**

# WorkManager (pulled in by Google Mobile Ads)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Room (used by WorkManager WorkDatabase)
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
-keepclassmembers class * {
    @androidx.room.* <methods>;
}
-dontwarn androidx.room.paging.**

# App Startup initializer used for WorkManager
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer {
    <init>();
}
