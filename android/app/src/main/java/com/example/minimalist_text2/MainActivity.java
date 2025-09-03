package com.example.minimalist_text2;
import android.content.Intent;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.app.usage.UsageEvents;
import android.app.AppOpsManager;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
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
    private static final String PREFS_NAME = "PickupPrefs";
    private static final String PICKUP_COUNT_KEY = "pickup_count";
    private static final String FOCUS_CHANNEL = "focus_mode_channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        switch (call.method) {
                            case "getUsageStats":
                                if (!isUsageAccessGranted()) {
                                    result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                    return;
                                }
                                result.success(getUsageStats());
                                break;
                            case "getAllUsageStats":
                                if (!isUsageAccessGranted()) {
                                    result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                    return;
                                }
                                long selectedDate = call.arguments();
                                result.success(getAllUsageStats(getStartOfDay(selectedDate)));
                                break;
                            case "getTotalScreenTime":
                                if (!isUsageAccessGranted()) {
                                    result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                    return;
                                }
                                long todayDate = call.arguments();
                                result.success(getTotalScreenTime(todayDate));
                                break;
                            case "getYesterdayScreenTime":
                                if (!isUsageAccessGranted()) {
                                    result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                    return;
                                }
                                Calendar cal = Calendar.getInstance();
                                cal.add(Calendar.DATE, -1);
                                long yesterdayStart = getStartOfDay(cal.getTimeInMillis()); // ✅ FIXED: ensure it's start of day
                                long yesterdayScreenTime = getTotalScreenTime(yesterdayStart);
                                Log.d("DEBUG_YESTERDAY", "Yesterday timestamp: " + yesterdayStart + ", screen time: " + yesterdayScreenTime);
                                result.success(yesterdayScreenTime);
                                break;
                            case "getPickupCount":
                                SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
                                int pickups = prefs.getInt(PICKUP_COUNT_KEY, 0);
                                result.success(pickups);
                                break;
                            default:
                                result.notImplemented();
                        }
                    }
                }
        );
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), FOCUS_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startFocusMode")) {
                        String password = call.argument("password");
                        ArrayList<String> blockedApps = call.argument("blockedApps");
                        int durationInSeconds = call.argument("duration");

                        Intent serviceIntent = new Intent(this, ForegroundMonitorService.class);
                        serviceIntent.putExtra("password", password);
                        serviceIntent.putStringArrayListExtra("blockedApps", blockedApps);
                        serviceIntent.putExtra("duration", durationInSeconds);

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent);
                        } else {
                            startService(serviceIntent);
                        }
                        result.success(true);
                    } else {
                        result.notImplemented();
                    }
                });

    }

    private boolean isUsageAccessGranted() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private long getTotalScreenTime(long timestamp) {
        long totalScreenTime = 0;
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();

        long startTime = getStartOfDay(timestamp);
        long endTime = getEndOfDay(timestamp);

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
                if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
                    totalScreenTime += entry.getValue();
                }
            } catch (PackageManager.NameNotFoundException e) {
                Log.e("DEBUG_TOTAL_SCREEN_TIME", "App Not Found: " + entry.getKey());
            }
        }
        return totalScreenTime;
    }

    private long getStartOfDay(long timestamp) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(timestamp);
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
    private List<Map<String, Object>> getAllUsageStats(long selectedDate) {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();

        long startTime = getStartOfDay(selectedDate);
        long endTime = getEndOfDay(selectedDate);

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
                long usageDuration = event.getTimeStamp() - appStartTimes.get(packageName);
                if (usageDuration > 0) {
                    appUsageMap.put(packageName, appUsageMap.getOrDefault(packageName, 0L) + usageDuration);
                }
                appStartTimes.remove(packageName);
            }
        }

        List<ApplicationInfo> installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA);
        List<Map<String, Object>> finalUsageList = new ArrayList<>();

        for (ApplicationInfo appInfo : installedApps) {
            if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) continue;

            String packageName = appInfo.packageName;
            String appName = packageManager.getApplicationLabel(appInfo).toString();
            Drawable icon = packageManager.getApplicationIcon(appInfo);
            String iconBase64 = bitmapToBase64(drawableToBitmap(icon));

            long screenTime = appUsageMap.getOrDefault(packageName, 0L);

            Map<String, Object> appUsage = new HashMap<>();
            appUsage.put("appName", appName);
            appUsage.put("packageName", packageName);
            appUsage.put("icon", iconBase64);
            appUsage.put("totalTimeInForeground", screenTime);

            finalUsageList.add(appUsage);
        }

        finalUsageList.sort((a, b) -> Long.compare((long) b.get("totalTimeInForeground"), (long) a.get("totalTimeInForeground")));
        return finalUsageList;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();

        long endTime = System.currentTimeMillis();
        long startTime = getStartOfDay(System.currentTimeMillis());

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
                long usageDuration = event.getTimeStamp() - appStartTimes.get(packageName);
                if (usageDuration > 0) {
                    appUsageMap.put(packageName, appUsageMap.getOrDefault(packageName, 0L) + usageDuration);
                }
                appStartTimes.remove(packageName);
            }
        }

        List<Map<String, Object>> finalUsageList = new ArrayList<>();
        for (Map.Entry<String, Long> entry : appUsageMap.entrySet()) {
            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(entry.getKey(), 0);
                if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) continue;
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

        finalUsageList.sort((a, b) -> Long.compare((long) b.get("totalTimeInForeground"), (long) a.get("totalTimeInForeground")));
        return finalUsageList;
    }

    private Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable == null) {
            return Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888);
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
