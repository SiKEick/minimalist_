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
import android.app.ActivityManager;
import android.app.ActivityManager.RunningAppProcessInfo;
import java.util.List;
import android.content.Context;
import java.util.Iterator;
import android.app.ActivityManager.RunningServiceInfo;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;

import java.util.SortedMap;
import java.util.TreeMap;


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
        String currentApp = "NULL";
        if(android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            UsageStatsManager usm = (UsageStatsManager) this.getSystemService(Context.USAGE_STATS_SERVICE);
            long time = System.currentTimeMillis();
            List<UsageStats> appList = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY,  time - 1000*1000, time);
            if (appList != null && appList.size() > 0) {
                SortedMap<Long, UsageStats> mySortedMap = new TreeMap<Long, UsageStats>();
                for (UsageStats usageStats : appList) {
                    mySortedMap.put(usageStats.getLastTimeUsed(), usageStats);
                }
                if (mySortedMap != null && !mySortedMap.isEmpty()) {
                    currentApp = mySortedMap.get(mySortedMap.lastKey()).getPackageName();
                }
            }
        } else {
            ActivityManager am = (ActivityManager)this.getSystemService(Context.ACTIVITY_SERVICE);
            List<ActivityManager.RunningAppProcessInfo> tasks = am.getRunningAppProcesses();
            currentApp = tasks.get(0).processName;
        }

        Log.e(TAG, "Current App in foreground is: " + currentApp);
        return currentApp;
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