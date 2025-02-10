package com.example.minimalist_text2;

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
                        if (call.method.equals("getUsageStats")) {
                            if (!isUsageAccessGranted()) {
                                result.error("PERMISSION_DENIED", "Usage Access permission is not granted", null);
                                return;
                            }
                            List<Map<String, Object>> usageStats = getUsageStats();
                            result.success(usageStats);
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

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();
        Calendar calendar = Calendar.getInstance();

        long endTime = calendar.getTimeInMillis(); // Current time
        calendar.set(Calendar.HOUR_OF_DAY, 0);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();

        List<UsageStats> usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime);

        Log.d("DEBUG_RAW_USAGE_STATS", "------ Raw Usage Data ------");

        // Store all occurrences of each app
        Map<String, List<Long>> usageTimeMap = new HashMap<>();

        for (UsageStats stats : usageStatsList) {
            long foregroundTime = stats.getTotalTimeInForeground();
            String packageName = stats.getPackageName();

            if (foregroundTime > 0) {
                Log.d("DEBUG_RAW_USAGE_STATS", "App: " + packageName + " - Foreground Time: " + foregroundTime);

                // Add usage time to the list for that package
                usageTimeMap.putIfAbsent(packageName, new ArrayList<>());
                usageTimeMap.get(packageName).add(foregroundTime);
            }
        }

        // Prepare the final result
        List<Map<String, Object>> finalUsageList = new ArrayList<>();

        for (Map.Entry<String, List<Long>> entry : usageTimeMap.entrySet()) {
            String packageName = entry.getKey();
            List<Long> timeList = entry.getValue();

            // Calculate the average time for this app
            long total = 0;
            for (long time : timeList) {
                total += time;
            }
            long averageTime = total / timeList.size(); // Taking the average

            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(packageName, 0);
                if ((appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) {
                    continue; // Skip system apps
                }

                String appName = packageManager.getApplicationLabel(appInfo).toString();
                Drawable icon = packageManager.getApplicationIcon(appInfo);
                String iconBase64 = bitmapToBase64(drawableToBitmap(icon));

                Map<String, Object> appUsage = new HashMap<>();
                appUsage.put("appName", appName);
                appUsage.put("icon", iconBase64);
                appUsage.put("totalTimeInForeground", averageTime);

                finalUsageList.add(appUsage);

            } catch (PackageManager.NameNotFoundException e) {
                Log.e("DEBUG_USAGE_STATS", "App Not Found: " + packageName);
            }
        }

        // Sort apps by usage time (highest first)
        finalUsageList.sort((a, b) -> Long.compare((long) b.get("totalTimeInForeground"), (long) a.get("totalTimeInForeground")));

        return finalUsageList.size() > 5 ? finalUsageList.subList(0, 5) : finalUsageList;
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
