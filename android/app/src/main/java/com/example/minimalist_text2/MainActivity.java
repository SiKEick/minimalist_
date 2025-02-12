package com.example.minimalist_text2;
import android.app.usage.UsageEvents;
import android.app.AppOpsManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.app/usage";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        if (call.method.equals("getUsageStats")) { // For Main Screen (Top 5)
                            if (!isUsageAccessGranted()) {
                                result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                return;
                            }
                            List<Map<String, Object>> usageStats = getUsageStats();
                            result.success(usageStats);
                        } else if (call.method.equals("getAllUsageStats")) { // For Activity Screen (All apps >1 min)
                            if (!isUsageAccessGranted()) {
                                result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                return;
                            }
                            List<Map<String, Object>> allUsageStats = getAllUsageStats();
                            result.success(allUsageStats);
                        } else if (call.method.equals("getTotalScreenTime")) { // Common total screen time
                            if (!isUsageAccessGranted()) {
                                result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                return;
                            }
                            long totalScreenTime = getTotalScreenTime();
                            result.success(totalScreenTime);
                        } else {
                            result.notImplemented();
                        }
                    }

                }
        );
    }

    private boolean isUsageAccessGranted() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private long getTotalScreenTime() {
        long totalScreenTime = 0;
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();

        long endTime = System.currentTimeMillis();
        long startTime = getStartOfDay(); // Midnight today

        UsageEvents usageEvents = usageStatsManager.queryEvents(startTime, endTime);
        Map<String, Long> appUsageMap = new HashMap<>();
        Map<String, Long> appStartTimes = new HashMap<>();

        UsageEvents.Event event = new UsageEvents.Event();

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            String packageName = event.getPackageName();

            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                appStartTimes.put(packageName, event.getTimeStamp());
            } else if (event.getEventType() == UsageEvents.Event.MOVE_TO_BACKGROUND && appStartTimes.containsKey(packageName)) {
                long duration = event.getTimeStamp() - appStartTimes.get(packageName);

                if (duration > 0) {
                    appUsageMap.put(packageName, appUsageMap.getOrDefault(packageName, 0L) + duration);
                }
                appStartTimes.remove(packageName);
            }
        }

        for (Map.Entry<String, Long> entry : appUsageMap.entrySet()) {
            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(entry.getKey(), 0);

                // **Filter: Only count installed (non-system) apps**
                if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
                    totalScreenTime += entry.getValue();
                }
            } catch (PackageManager.NameNotFoundException e) {
                Log.e("DEBUG_TOTAL_SCREEN_TIME", "App Not Found: " + entry.getKey());
            }
        }

        Log.d("DEBUG_FINAL_SCREEN_TIME", "Total Installed Apps Screen Time Today: " + totalScreenTime);
        return totalScreenTime;
    }



    private long getStartOfDay() {
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        return calendar.getTimeInMillis();
    }

    private long getEndOfDay(long timestamp) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(timestamp);
        calendar.set(Calendar.HOUR_OF_DAY, 23);
        calendar.set(Calendar.MINUTE, 59);
        calendar.set(Calendar.SECOND, 59);
        calendar.set(Calendar.MILLISECOND, 999);
        return calendar.getTimeInMillis();
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getAllUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();
        long currentTime = System.currentTimeMillis();
        long endTime = getEndOfDay(currentTime);
        long startTime = getStartOfDay();

        UsageEvents usageEvents = usageStatsManager.queryEvents(startTime, endTime);
        Map<String, Long> appUsageMap = new HashMap<>();
        Map<String, Long> appStartTimes = new HashMap<>();

        UsageEvents.Event event = new UsageEvents.Event();

        // ✅ Collect screen time data
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            String packageName = event.getPackageName();

            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                appStartTimes.put(packageName, event.getTimeStamp());
            } else if (event.getEventType() == UsageEvents.Event.MOVE_TO_BACKGROUND && appStartTimes.containsKey(packageName)) {
                long usageDuration = event.getTimeStamp() - appStartTimes.get(packageName);
                if (usageDuration > 0) {
                    appUsageMap.put(packageName, appUsageMap.getOrDefault(packageName, 0L) + usageDuration);
                }
                appStartTimes.remove(packageName);
            }
        }

        // ✅ Get all installed apps
        List<ApplicationInfo> installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA);
        List<Map<String, Object>> finalUsageList = new ArrayList<>();

        for (ApplicationInfo appInfo : installedApps) {
            if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) continue; // Skip system apps

            String packageName = appInfo.packageName;
            String appName = packageManager.getApplicationLabel(appInfo).toString();
            Drawable icon = packageManager.getApplicationIcon(appInfo);
            String iconBase64 = bitmapToBase64(drawableToBitmap(icon));

            // ✅ If app has screen time, use it; otherwise, set to 0
            long screenTime = appUsageMap.getOrDefault(packageName, 0L);

            Map<String, Object> appUsage = new HashMap<>();
            appUsage.put("appName", appName);
            appUsage.put("packageName", packageName);
            appUsage.put("icon", iconBase64);
            appUsage.put("totalTimeInForeground", screenTime);

            finalUsageList.add(appUsage);
        }

        // ✅ Sort apps by screen time (highest first)
        finalUsageList.sort((a, b) -> Long.compare((long) b.get("totalTimeInForeground"), (long) a.get("totalTimeInForeground")));

        return finalUsageList;
    }



    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();
        long endTime = System.currentTimeMillis();
        long startTime = getStartOfDay(); // Midnight timestamp

        UsageEvents usageEvents = usageStatsManager.queryEvents(startTime, endTime);
        Map<String, Long> appUsageMap = new HashMap<>();
        Map<String, Long> appStartTimes = new HashMap<>();

        UsageEvents.Event event = new UsageEvents.Event();

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            String packageName = event.getPackageName();

            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                appStartTimes.put(packageName, event.getTimeStamp());
            } else if (event.getEventType() == UsageEvents.Event.MOVE_TO_BACKGROUND && appStartTimes.containsKey(packageName)) {
                long startTimeForApp = appStartTimes.get(packageName);
                long usageDuration = event.getTimeStamp() - startTimeForApp;

                if (usageDuration > 0) {
                    appUsageMap.put(packageName, appUsageMap.getOrDefault(packageName, 0L) + usageDuration);
                }

                appStartTimes.remove(packageName); // Remove after calculating
            }
        }

        List<Map<String, Object>> finalUsageList = new ArrayList<>();
        for (Map.Entry<String, Long> entry : appUsageMap.entrySet()) {
            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(entry.getKey(), 0);
                if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) {
                    continue;
                }
                String appName = packageManager.getApplicationLabel(appInfo).toString();
                Drawable icon = packageManager.getApplicationIcon(appInfo);
                String iconBase64 = bitmapToBase64(drawableToBitmap(icon));

                Map<String, Object> appUsage = new HashMap<>();
                appUsage.put("appName", appName);
                appUsage.put("packageName", entry.getKey());
                appUsage.put("icon", iconBase64);
                appUsage.put("totalTimeInForeground", entry.getValue());

                finalUsageList.add(appUsage);
            } catch (PackageManager.NameNotFoundException e) {
                Log.e("DEBUG_USAGE_STATS", "App Not Found: " + entry.getKey());
            }
        }

        // Sort by usage time (highest first)
        finalUsageList.sort((a, b) -> Long.compare((long) b.get("totalTimeInForeground"), (long) a.get("totalTimeInForeground")));

        return finalUsageList;
    }


    private Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable == null) {
            return Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888); // Return a tiny blank bitmap
        }
        if (drawable instanceof BitmapDrawable) {
            return ((BitmapDrawable) drawable).getBitmap();
        }
        Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    private String bitmapToBase64(Bitmap bitmap) {
        if (bitmap == null) return "";
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }
}