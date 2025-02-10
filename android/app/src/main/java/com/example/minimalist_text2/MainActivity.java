package com.example.minimalist_text2;

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
                            List<Map<String, Object>> usageStats = getUsageStats();
                            result.success(usageStats);
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private List<Map<String, Object>> getUsageStats() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        PackageManager packageManager = getPackageManager();
        Calendar calendar = Calendar.getInstance();
        long endTime = calendar.getTimeInMillis();
        calendar.add(Calendar.DAY_OF_YEAR, -1);
        long startTime = calendar.getTimeInMillis();

        List<UsageStats> usageStatsList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);
        List<Map<String, Object>> eventList = new ArrayList<>();

        for (UsageStats usageStats : usageStatsList) {
            Map<String, Object> appUsage = new HashMap<>();
            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(usageStats.getPackageName(), 0);
                String appName = (String) packageManager.getApplicationLabel(appInfo);
                appUsage.put("appName", appName);

                // Fetch app icon and convert to Base64
                Drawable icon = packageManager.getApplicationIcon(appInfo);
                Bitmap bitmap = drawableToBitmap(icon);
                String iconBase64 = bitmapToBase64(bitmap);
                appUsage.put("icon", iconBase64);

                // Debugging: Print the first 20 characters of the Base64 string
                System.out.println("Base64 Icon for " + appName + ": " +
                        iconBase64.substring(0, Math.min(20, iconBase64.length())) + "...");

            } catch (PackageManager.NameNotFoundException e) {
                appUsage.put("appName", usageStats.getPackageName());
                appUsage.put("icon", ""); // Fallback if icon isn't found
                Log.e("MainActivity", "App not found: " + usageStats.getPackageName(), e);
            }
            appUsage.put("totalTimeInForeground", usageStats.getTotalTimeInForeground());
            eventList.add(appUsage);
        }
        return eventList;
    }

    // Convert Drawable to Bitmap
    private Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable instanceof BitmapDrawable) {
            return ((BitmapDrawable) drawable).getBitmap();
        }
        Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    // Convert Bitmap to Base64
    private String bitmapToBase64(Bitmap bitmap) {
        if (bitmap == null) return ""; // Prevent NullPointerException
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.NO_WRAP); // FIXED: Use NO_WRAP to prevent errors
    }
}
