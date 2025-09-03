package com.example.minimalist_text2;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import java.util.ArrayList;

public class ForegroundMonitorService extends Service {
    private static final String CHANNEL_ID = "FocusModeServiceChannel";
    private static final String TAG = "FocusModeService";

    private ArrayList<String> blockedApps;  // PACKAGE NAMES
    private String password;
    private long endTimeMillis;
    private Handler handler = new Handler();

    private String lastLockedApp = "";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Service created");
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        blockedApps = intent.getStringArrayListExtra("blockedApps");
        password = intent.getStringExtra("password");
        int durationSeconds = intent.getIntExtra("duration", 0);
        endTimeMillis = System.currentTimeMillis() + (durationSeconds * 1000);

        Log.d(TAG, "Service started");
        Log.d(TAG, "Blocked Apps: " + blockedApps);
        Log.d(TAG, "Password: " + password);
        Log.d(TAG, "Duration (seconds): " + durationSeconds);

        startForeground(1, getNotification());
        monitorApps();

        return START_STICKY;
    }

    private void monitorApps() {
        handler.postDelayed(() -> {
            if (System.currentTimeMillis() > endTimeMillis) {
                Log.d(TAG, "Focus Mode duration ended, stopping service");
                stopSelf();
                return;
            }

            String foregroundApp = getForegroundApp();
            Log.d(TAG, "Foreground App: " + foregroundApp);

            if (blockedApps != null && blockedApps.contains(foregroundApp)) {
                Log.d(TAG, "Blocked app detected: " + foregroundApp);

                if (!foregroundApp.equals(lastLockedApp)) {
                    Log.d(TAG, "Launching LockActivity for: " + foregroundApp);
                    lastLockedApp = foregroundApp;

                    Intent lockIntent = new Intent(this, LockActivity.class);
                    lockIntent.putExtra("password", password);
                    lockIntent.putExtra(LockActivity.EXTRA_PACKAGE_NAME, foregroundApp);
                    lockIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    startActivity(lockIntent);
                }
            } else {
                if (!foregroundApp.isEmpty()) {
                    Log.d(TAG, "App is not blocked: " + foregroundApp);
                }
                lastLockedApp = "";
            }

            monitorApps();
        }, 2000);
    }

    private String getForegroundApp() {
        UsageStatsManager usageStatsManager = (UsageStatsManager) getSystemService(USAGE_STATS_SERVICE);
        long endTime = System.currentTimeMillis();
        long beginTime = endTime - 2000;

        UsageEvents usageEvents = usageStatsManager.queryEvents(beginTime, endTime);
        UsageEvents.Event event = new UsageEvents.Event();
        String packageName = "";
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event);
            if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                packageName = event.getPackageName();
            }
        }
        Log.d(TAG, "Detected Foreground Package: " + packageName);
        return packageName;
    }

    private Notification getNotification() {
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Focus Mode Active")
                .setContentText("Stay focused!")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Focus Mode Service Channel",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(serviceChannel);
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        Log.d(TAG, "Service destroyed");
        super.onDestroy();
    }
}
